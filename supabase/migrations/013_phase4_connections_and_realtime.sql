-- ============================================================================
-- MELSAVA — Phase 4: Real Connections, Secure Messaging, Read Receipts & Realtime
-- Migration: 013_phase4_connections_and_realtime.sql
-- Description:
--   1. Security helper `can_access_conversation(UUID)`.
--   2. Tightened RLS policies for `conversations`, `conversation_members`, and `messages`.
--   3. Secure RPCs:
--      - `get_user_connections()`: Real mutual connections, actual last message, no fake scores.
--      - `get_user_inbox_threads()`: Real conversation threads with real unread counts.
--      - `get_conversation_messages()`: Chronological message history with pagination support.
--      - `get_or_create_conversation_for_connection()`: Resolves or safely creates direct threads.
--      - `send_conversation_message()`: Server-validated messaging with trim & 1000 char limit.
--      - `mark_conversation_read()`: Atomic read receipts for incoming messages.
--   4. Idempotent Supabase Realtime publication registration for `public.messages`.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Helper Function: can_access_conversation
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.can_access_conversation(p_conversation_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid        UUID := auth.uid();
    v_conn_id    UUID;
    v_partner_id UUID;
BEGIN
    IF v_uid IS NULL OR p_conversation_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Verify caller is a member of this conversation
    IF NOT EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_id = p_conversation_id
          AND user_id = v_uid
    ) THEN
        RETURN FALSE;
    END IF;

    -- Check caller account suspension
    IF EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = v_uid AND is_suspended = TRUE
    ) THEN
        RETURN FALSE;
    END IF;

    -- Check associated connection & partner eligibility if direct conversation
    SELECT connection_id INTO v_conn_id
      FROM public.conversations
     WHERE id = p_conversation_id;

    IF v_conn_id IS NOT NULL THEN
        -- Find the other conversation partner
        SELECT cm.user_id INTO v_partner_id
          FROM public.conversation_members cm
         WHERE cm.conversation_id = p_conversation_id
           AND cm.user_id != v_uid
         LIMIT 1;

        IF v_partner_id IS NOT NULL THEN
            -- Check if partner is suspended
            IF EXISTS (
                SELECT 1 FROM public.profiles
                WHERE id = v_partner_id AND is_suspended = TRUE
            ) THEN
                RETURN FALSE;
            END IF;

            -- Check block in either direction
            IF EXISTS (
                SELECT 1 FROM public.blocks b
                WHERE (b.blocker_id = v_uid AND b.blocked_id = v_partner_id)
                   OR (b.blocker_id = v_partner_id AND b.blocked_id = v_uid)
            ) THEN
                RETURN FALSE;
            END IF;
        END IF;
    END IF;

    RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.can_access_conversation(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_access_conversation(UUID) TO authenticated;


-- ----------------------------------------------------------------------------
-- 2. Tightened RLS Policies for Conversations & Messages
-- ----------------------------------------------------------------------------

-- Conversations SELECT policy
DROP POLICY IF EXISTS "conversations_select" ON public.conversations;
CREATE POLICY "conversations_select"
    ON public.conversations FOR SELECT
    USING (public.can_access_conversation(id));

-- Conversation Members SELECT policy
DROP POLICY IF EXISTS "conversation_members_select" ON public.conversation_members;
CREATE POLICY "conversation_members_select"
    ON public.conversation_members FOR SELECT
    USING (public.can_access_conversation(conversation_id));

-- Messages SELECT policy
DROP POLICY IF EXISTS "messages_select" ON public.messages;
CREATE POLICY "messages_select"
    ON public.messages FOR SELECT
    USING (public.can_access_conversation(conversation_id));

-- Messages INSERT policy (Restricted: caller must own message and have access)
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
CREATE POLICY "messages_insert"
    ON public.messages FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id
        AND public.can_access_conversation(conversation_id)
    );

-- Messages UPDATE policy (Restricted: only for marking read receipts on incoming messages)
DROP POLICY IF EXISTS "messages_update" ON public.messages;
CREATE POLICY "messages_update"
    ON public.messages FOR UPDATE
    USING (
        auth.uid() != sender_id
        AND public.can_access_conversation(conversation_id)
    )
    WITH CHECK (
        auth.uid() != sender_id
        AND public.can_access_conversation(conversation_id)
    );


-- ----------------------------------------------------------------------------
-- 3. RPC: get_user_connections
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_user_connections();

CREATE OR REPLACE FUNCTION public.get_user_connections()
RETURNS TABLE (
    connection_id        UUID,
    conversation_id      UUID,
    partner_id           UUID,
    partner_name         TEXT,
    partner_avatar       TEXT,
    partner_bio          TEXT,
    connection_type      TEXT,
    experience_id        UUID,
    experience_title     TEXT,
    last_message         TEXT,
    last_message_at      TIMESTAMPTZ,
    created_at           TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    WITH latest_messages AS (
        SELECT DISTINCT ON (m.conversation_id)
            m.conversation_id,
            m.content AS message_text,
            m.created_at AS message_time
        FROM public.messages m
        ORDER BY m.conversation_id, m.created_at DESC
    )
    SELECT
        c.id AS connection_id,
        conv.id AS conversation_id,
        p.id AS partner_id,
        COALESCE(p.display_name, 'MELSAVA Member') AS partner_name,
        COALESCE(p.avatar_url, '') AS partner_avatar,
        COALESCE(p.bio, '') AS partner_bio,
        c.connection_type::TEXT,
        c.experience_id,
        COALESCE(e.title, 'Shared Experience') AS experience_title,
        lm.message_text AS last_message,
        lm.message_time AS last_message_at,
        c.created_at
    FROM public.connections c
    JOIN public.profiles p ON p.id = (CASE WHEN c.user_a_id = v_uid THEN c.user_b_id ELSE c.user_a_id END)
    LEFT JOIN public.experiences e ON e.id = c.experience_id
    LEFT JOIN public.conversations conv ON conv.connection_id = c.id
    LEFT JOIN latest_messages lm ON lm.conversation_id = conv.id
    WHERE (c.user_a_id = v_uid OR c.user_b_id = v_uid)
      AND p.is_suspended = FALSE
      AND NOT EXISTS (
          SELECT 1 FROM public.blocks b
          WHERE (b.blocker_id = v_uid AND b.blocked_id = p.id)
             OR (b.blocker_id = p.id AND b.blocked_id = v_uid)
      )
    ORDER BY COALESCE(lm.message_time, c.created_at) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_connections() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_connections() TO authenticated;


-- ----------------------------------------------------------------------------
-- 4. RPC: get_user_inbox_threads
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_user_inbox_threads();

CREATE OR REPLACE FUNCTION public.get_user_inbox_threads()
RETURNS TABLE (
    conversation_id      UUID,
    connection_id        UUID,
    partner_id           UUID,
    partner_name         TEXT,
    partner_avatar       TEXT,
    connection_type      TEXT,
    experience_title     TEXT,
    last_message         TEXT,
    last_message_at      TIMESTAMPTZ,
    unread_count         BIGINT,
    created_at           TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    WITH unread_counts AS (
        SELECT 
            m.conversation_id,
            COUNT(*) AS cnt
        FROM public.messages m
        WHERE m.sender_id != v_uid
          AND m.is_read = FALSE
        GROUP BY m.conversation_id
    ),
    latest_messages AS (
        SELECT DISTINCT ON (m.conversation_id)
            m.conversation_id,
            m.content AS message_text,
            m.created_at AS message_time
        FROM public.messages m
        ORDER BY m.conversation_id, m.created_at DESC
    )
    SELECT
        conv.id AS conversation_id,
        c.id AS connection_id,
        p.id AS partner_id,
        COALESCE(p.display_name, 'MELSAVA Member') AS partner_name,
        COALESCE(p.avatar_url, '') AS partner_avatar,
        COALESCE(c.connection_type::TEXT, 'friendship') AS connection_type,
        COALESCE(e.title, 'Shared Experience') AS experience_title,
        lm.message_text AS last_message,
        lm.message_time AS last_message_at,
        COALESCE(uc.cnt, 0)::BIGINT AS unread_count,
        conv.created_at
    FROM public.conversations conv
    JOIN public.conversation_members cm ON cm.conversation_id = conv.id AND cm.user_id = v_uid
    JOIN public.conversation_members other_cm ON other_cm.conversation_id = conv.id AND other_cm.user_id != v_uid
    JOIN public.profiles p ON p.id = other_cm.user_id
    LEFT JOIN public.connections c ON c.id = conv.connection_id
    LEFT JOIN public.experiences e ON e.id = c.experience_id
    LEFT JOIN latest_messages lm ON lm.conversation_id = conv.id
    LEFT JOIN unread_counts uc ON uc.conversation_id = conv.id
    WHERE p.is_suspended = FALSE
      AND NOT EXISTS (
          SELECT 1 FROM public.blocks b
          WHERE (b.blocker_id = v_uid AND b.blocked_id = p.id)
             OR (b.blocker_id = p.id AND b.blocked_id = v_uid)
      )
    ORDER BY COALESCE(lm.message_time, conv.updated_at, conv.created_at) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_inbox_threads() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_inbox_threads() TO authenticated;


-- ----------------------------------------------------------------------------
-- 5. RPC: get_conversation_messages
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_conversation_messages(UUID);
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
    ORDER BY created_at ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_conversation_messages(UUID, INT, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_conversation_messages(UUID, INT, TIMESTAMPTZ) TO authenticated;


-- ----------------------------------------------------------------------------
-- 6. RPC: get_or_create_conversation_for_connection
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_or_create_conversation_for_connection(UUID);

CREATE OR REPLACE FUNCTION public.get_or_create_conversation_for_connection(
    p_connection_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid        UUID := auth.uid();
    v_conn       RECORD;
    v_conv_id    UUID;
    v_partner_id UUID;
    v_now        TIMESTAMPTZ := now();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO v_conn
    FROM public.connections
    WHERE id = p_connection_id
      AND (user_a_id = v_uid OR user_b_id = v_uid);

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Connection not found or unauthorized';
    END IF;

    v_partner_id := CASE WHEN v_conn.user_a_id = v_uid THEN v_conn.user_b_id ELSE v_conn.user_a_id END;

    -- Check neither user is suspended
    IF EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id IN (v_uid, v_partner_id) AND is_suspended = TRUE
    ) THEN
        RAISE EXCEPTION 'Cannot open conversation with suspended user.';
    END IF;

    -- Check neither user has blocked the other
    IF EXISTS (
        SELECT 1 FROM public.blocks b
        WHERE (b.blocker_id = v_uid AND b.blocked_id = v_partner_id)
           OR (b.blocker_id = v_partner_id AND b.blocked_id = v_uid)
    ) THEN
        RAISE EXCEPTION 'Cannot open conversation with a blocked user.';
    END IF;

    -- Look for existing conversation
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE connection_id = p_connection_id
    LIMIT 1;

    IF v_conv_id IS NULL THEN
        INSERT INTO public.conversations (type, connection_id, created_at, updated_at)
        VALUES ('direct', p_connection_id, v_now, v_now)
        ON CONFLICT (connection_id) DO UPDATE SET updated_at = v_now
        RETURNING id INTO v_conv_id;

        INSERT INTO public.conversation_members (conversation_id, user_id)
        VALUES 
            (v_conv_id, v_conn.user_a_id),
            (v_conv_id, v_conn.user_b_id)
        ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END IF;

    RETURN v_conv_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_or_create_conversation_for_connection(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_or_create_conversation_for_connection(UUID) TO authenticated;


-- ----------------------------------------------------------------------------
-- 7. RPC: send_conversation_message
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.send_conversation_message(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.send_conversation_message(
    p_conversation_id UUID,
    p_content         TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid          UUID := auth.uid();
    v_msg_id       UUID;
    v_now          TIMESTAMPTZ := now();
    v_clean_text   TEXT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Trim whitespace
    v_clean_text := TRIM(p_content);

    -- Reject empty or whitespace-only messages
    IF v_clean_text IS NULL OR v_clean_text = '' THEN
        RAISE EXCEPTION 'Message content cannot be empty.';
    END IF;

    -- Reject messages longer than 1,000 characters
    IF LENGTH(v_clean_text) > 1000 THEN
        RAISE EXCEPTION 'Message exceeds 1,000 character maximum limit.';
    END IF;

    -- Verify access via security helper (validates membership, connection, blocks, suspension)
    IF NOT public.can_access_conversation(p_conversation_id) THEN
        RAISE EXCEPTION 'Unauthorized conversation member';
    END IF;

    -- Insert message with server timestamp
    INSERT INTO public.messages (conversation_id, sender_id, content, is_read, created_at)
    VALUES (p_conversation_id, v_uid, v_clean_text, FALSE, v_now)
    RETURNING id INTO v_msg_id;

    -- Update conversation updated_at
    UPDATE public.conversations
       SET updated_at = v_now
     WHERE id = p_conversation_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message_id', v_msg_id,
        'conversation_id', p_conversation_id,
        'sender_id', v_uid,
        'content', v_clean_text,
        'is_read', FALSE,
        'created_at', v_now
    );
END;
$$;

REVOKE ALL ON FUNCTION public.send_conversation_message(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_conversation_message(UUID, TEXT) TO authenticated;


-- ----------------------------------------------------------------------------
-- 8. RPC: mark_conversation_read
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.mark_conversation_read(UUID);

CREATE OR REPLACE FUNCTION public.mark_conversation_read(
    p_conversation_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid           UUID := auth.uid();
    v_updated_count INTEGER := 0;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Verify access
    IF NOT public.can_access_conversation(p_conversation_id) THEN
        RAISE EXCEPTION 'Unauthorized conversation access';
    END IF;

    -- Update only incoming unread messages
    UPDATE public.messages
       SET is_read = TRUE
     WHERE conversation_id = p_conversation_id
       AND sender_id != v_uid
       AND is_read = FALSE;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    RETURN v_updated_count;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_conversation_read(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_conversation_read(UUID) TO authenticated;


-- ----------------------------------------------------------------------------
-- 9. Realtime Publication Setup
-- ----------------------------------------------------------------------------
ALTER TABLE public.messages REPLICA IDENTITY FULL;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' 
              AND schemaname = 'public' 
              AND tablename = 'messages'
        ) THEN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
        END IF;
    END IF;
END;
$$;
