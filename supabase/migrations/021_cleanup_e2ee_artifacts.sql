-- ============================================================================
-- Migration 021: Clean up Unused E2EE Artifacts & Columns
--
-- Aligns database schema with Dating App Industry Standard Messaging Architecture (Option B):
-- - Restores get_conversation_messages to clean 6-column signature
-- - Drops obsolete E2EE RPCs
-- - Drops obsolete E2EE tables (user_devices, user_one_time_prekeys)
-- - Removes unused E2EE metadata columns from public.messages
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Restore get_conversation_messages to clean 6-column output
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_conversation_messages(UUID, INT, TIMESTAMPTZ);

CREATE OR REPLACE FUNCTION public.get_conversation_messages(
    p_conversation_id UUID,
    p_limit           INT DEFAULT 50,
    p_before          TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    message_id   UUID,
    sender_id    UUID,
    content      TEXT,
    is_read      BOOLEAN,
    created_at   TIMESTAMPTZ,
    is_me        BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid        UUID := auth.uid();
    v_eff_limit  INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 100);
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Verify caller access via security helper
    IF NOT public.can_access_conversation(p_conversation_id) THEN
        RAISE EXCEPTION 'Unauthorized conversation access';
    END IF;

    RETURN QUERY
    WITH msg_page AS (
        SELECT
            m.id AS message_id,
            m.sender_id,
            m.content,
            m.is_read,
            m.created_at,
            (m.sender_id = v_uid) AS is_me
        FROM public.messages m
        WHERE m.conversation_id = p_conversation_id
          AND (p_before IS NULL OR m.created_at < p_before)
        ORDER BY m.created_at DESC
        LIMIT v_eff_limit
    )
    SELECT * FROM msg_page
    ORDER BY msg_page.created_at ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_conversation_messages(UUID, INT, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_conversation_messages(UUID, INT, TIMESTAMPTZ) TO authenticated;

-- ----------------------------------------------------------------------------
-- 2. Drop obsolete E2EE RPCs
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.send_e2ee_conversation_message(UUID, UUID, TEXT, INT, INT, TEXT);
DROP FUNCTION IF EXISTS public.fetch_user_prekey_bundle(UUID, INT);
DROP FUNCTION IF EXISTS public.register_device_keys(INT, INT, TEXT, INT, TEXT, TEXT, JSONB);
DROP FUNCTION IF EXISTS public.replenish_one_time_prekeys(INT, JSONB);
DROP FUNCTION IF EXISTS public.get_unconsumed_prekey_count(INT);

-- ----------------------------------------------------------------------------
-- 3. Drop obsolete E2EE tables (cascades to dependent foreign keys, RLS, indexes)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS public.user_one_time_prekeys CASCADE;
DROP TABLE IF EXISTS public.user_devices CASCADE;

-- ----------------------------------------------------------------------------
-- 4. Drop idempotent index if exists
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS public.idx_messages_idempotent;

-- ----------------------------------------------------------------------------
-- 5. Remove unused E2EE metadata columns from public.messages
-- ----------------------------------------------------------------------------
ALTER TABLE public.messages DROP COLUMN IF EXISTS is_encrypted;
ALTER TABLE public.messages DROP COLUMN IF EXISTS encrypted_payload;
ALTER TABLE public.messages DROP COLUMN IF EXISTS sender_device_id;
ALTER TABLE public.messages DROP COLUMN IF EXISTS recipient_device_id;
ALTER TABLE public.messages DROP COLUMN IF EXISTS recipient_id;
ALTER TABLE public.messages DROP COLUMN IF EXISTS client_request_id;
