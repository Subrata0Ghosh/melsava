-- ============================================================================
-- MELSAVA — Phase 5 All-in-One Migration
-- Description: Safety, Moderation, Profile Management & Account Settings
-- Run this script in the Supabase SQL Editor if applying manually.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Phase 4 Security Preflight: Restrict Messages Direct Mutations
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_insert_sender" ON public.messages;
REVOKE INSERT ON public.messages FROM anon, authenticated;

DROP POLICY IF EXISTS "messages_update" ON public.messages;
DROP POLICY IF EXISTS "messages_update_read" ON public.messages;
REVOKE UPDATE ON public.messages FROM anon, authenticated;

DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_select_member" ON public.messages;
CREATE POLICY "messages_select"
    ON public.messages FOR SELECT
    USING (public.can_access_conversation(conversation_id));

DROP FUNCTION IF EXISTS public.can_access_conversation(UUID) CASCADE;

CREATE OR REPLACE FUNCTION public.can_access_conversation(p_conversation_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
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

    -- Verify caller is a confirmed member of this conversation
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
        SELECT cm.user_id INTO v_partner_id
          FROM public.conversation_members cm
         WHERE cm.conversation_id = p_conversation_id
           AND cm.user_id != v_uid
         LIMIT 1;

        IF v_partner_id IS NOT NULL THEN
            IF EXISTS (
                SELECT 1 FROM public.profiles
                WHERE id = v_partner_id AND is_suspended = TRUE
            ) THEN
                RETURN FALSE;
            END IF;

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
-- 2. Real Profile Management: Atomic Profile Update RPC
-- ----------------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.update_user_profile(TEXT, TEXT, TEXT, TEXT, TEXT[], TEXT, TEXT[], TEXT[], JSONB);

CREATE OR REPLACE FUNCTION public.update_user_profile(
    p_display_name          TEXT,
    p_avatar_url            TEXT,
    p_bio                   TEXT,
    p_city                  TEXT,
    p_interests             TEXT[],
    p_primary_intent        TEXT,
    p_secondary_intents     TEXT[],
    p_preferred_categories  TEXT[],
    p_discovery_preferences JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid           UUID := auth.uid();
    v_interest_name TEXT;
    v_interest_id   UUID;
    v_intent_name   TEXT;
    v_intent_id     UUID;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    IF p_display_name IS NULL OR char_length(TRIM(p_display_name)) < 2 THEN
        RAISE EXCEPTION 'Display name must be at least 2 characters.';
    END IF;

    IF char_length(TRIM(p_display_name)) > 50 THEN
        RAISE EXCEPTION 'Display name cannot exceed 50 characters.';
    END IF;

    -- 1. Update public.profiles without touching sensitive verification flags
    UPDATE public.profiles
       SET display_name = TRIM(p_display_name),
           avatar_url   = NULLIF(TRIM(p_avatar_url), ''),
           bio          = TRIM(p_bio),
           city         = TRIM(p_city),
           updated_at   = now()
     WHERE id = v_uid;

    -- 2. Update profile_interests
    DELETE FROM public.profile_interests WHERE profile_id = v_uid;
    IF p_interests IS NOT NULL THEN
        FOREACH v_interest_name IN ARRAY p_interests LOOP
            SELECT id INTO v_interest_id
              FROM public.interests
             WHERE lower(name) = lower(TRIM(v_interest_name))
             LIMIT 1;

            IF v_interest_id IS NOT NULL THEN
                INSERT INTO public.profile_interests (profile_id, interest_id)
                VALUES (v_uid, v_interest_id)
                ON CONFLICT DO NOTHING;
            END IF;
        END LOOP;
    END IF;

    -- 3. Update profile_intentions
    DELETE FROM public.profile_intentions WHERE profile_id = v_uid;
    IF p_primary_intent IS NOT NULL AND TRIM(p_primary_intent) != '' THEN
        SELECT id INTO v_intent_id
          FROM public.intentions
         WHERE lower(name) = lower(TRIM(p_primary_intent))
         LIMIT 1;

        IF v_intent_id IS NOT NULL THEN
            INSERT INTO public.profile_intentions (profile_id, intention_id, is_primary)
            VALUES (v_uid, v_intent_id, TRUE)
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    IF p_secondary_intents IS NOT NULL THEN
        FOREACH v_intent_name IN ARRAY p_secondary_intents LOOP
            IF lower(TRIM(v_intent_name)) != lower(COALESCE(TRIM(p_primary_intent), '')) THEN
                SELECT id INTO v_intent_id
                  FROM public.intentions
                 WHERE lower(name) = lower(TRIM(v_intent_name))
                 LIMIT 1;

                IF v_intent_id IS NOT NULL THEN
                    INSERT INTO public.profile_intentions (profile_id, intention_id, is_primary)
                    VALUES (v_uid, v_intent_id, FALSE)
                    ON CONFLICT DO NOTHING;
                END IF;
            END IF;
        END LOOP;
    END IF;

    -- 4. Update profile_private preferences
    UPDATE public.profile_private
       SET preferred_activity_categories = COALESCE(p_preferred_categories, preferred_activity_categories),
           discovery_preferences = COALESCE(p_discovery_preferences, discovery_preferences)
     WHERE user_id = v_uid;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'Profile updated successfully.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.update_user_profile(TEXT, TEXT, TEXT, TEXT, TEXT[], TEXT, TEXT[], TEXT[], JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_user_profile(TEXT, TEXT, TEXT, TEXT, TEXT[], TEXT, TEXT[], TEXT[], JSONB) TO authenticated;


-- ----------------------------------------------------------------------------
-- 3. Real Block Management RPCs
-- ----------------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.block_user(UUID);

CREATE OR REPLACE FUNCTION public.block_user(p_blocked_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    IF p_blocked_id IS NULL OR p_blocked_id = v_uid THEN
        RAISE EXCEPTION 'Cannot block yourself or invalid user ID.';
    END IF;

    INSERT INTO public.blocks (blocker_id, blocked_id)
    VALUES (v_uid, p_blocked_id)
    ON CONFLICT (blocker_id, blocked_id) DO NOTHING;

    RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.block_user(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.block_user(UUID) TO authenticated;


DROP FUNCTION IF EXISTS public.unblock_user(UUID);

CREATE OR REPLACE FUNCTION public.unblock_user(p_blocked_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    DELETE FROM public.blocks
     WHERE blocker_id = v_uid
       AND blocked_id = p_blocked_id;

    RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.unblock_user(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.unblock_user(UUID) TO authenticated;


DROP FUNCTION IF EXISTS public.get_blocked_users();

CREATE OR REPLACE FUNCTION public.get_blocked_users()
RETURNS TABLE (
    blocked_id   UUID,
    display_name TEXT,
    avatar_url   TEXT,
    blocked_at   TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    RETURN QUERY
    SELECT 
        b.blocked_id,
        COALESCE(p.display_name, 'MELSAVA Member') AS display_name,
        COALESCE(p.avatar_url, '') AS avatar_url,
        b.created_at AS blocked_at
    FROM public.blocks b
    JOIN public.profiles p ON p.id = b.blocked_id
    WHERE b.blocker_id = v_uid
    ORDER BY b.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_blocked_users() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_blocked_users() TO authenticated;


-- ----------------------------------------------------------------------------
-- 4. Real Reporting System RPC
-- ----------------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.submit_user_report(UUID, TEXT, TEXT, TEXT, UUID);

CREATE OR REPLACE FUNCTION public.submit_user_report(
    p_reported_user_id    UUID,
    p_reason              TEXT,
    p_description         TEXT DEFAULT NULL,
    p_content_type        TEXT DEFAULT 'profile',
    p_content_id          UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid          UUID := auth.uid();
    v_report_id    UUID;
    v_clean_desc   TEXT;
    v_clean_reason TEXT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    IF p_reported_user_id IS NULL OR p_reported_user_id = v_uid THEN
        RAISE EXCEPTION 'Invalid reported user: cannot report yourself.';
    END IF;

    v_clean_reason := TRIM(p_reason);
    IF v_clean_reason IS NULL OR v_clean_reason = '' THEN
        RAISE EXCEPTION 'Report reason is required.';
    END IF;

    v_clean_desc := TRIM(p_description);
    IF v_clean_desc IS NOT NULL AND LENGTH(v_clean_desc) > 500 THEN
        RAISE EXCEPTION 'Description exceeds maximum length of 500 characters.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_reported_user_id) THEN
        RAISE EXCEPTION 'Reported user does not exist.';
    END IF;

    INSERT INTO public.reports (
        reporter_id,
        reported_user_id,
        reported_content_type,
        reported_content_id,
        reason,
        description,
        status,
        created_at
    )
    VALUES (
        v_uid,
        p_reported_user_id,
        COALESCE(p_content_type, 'profile'),
        p_content_id,
        v_clean_reason,
        v_clean_desc,
        'pending',
        now()
    )
    RETURNING id INTO v_report_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'report_id', v_report_id,
        'message', 'Report submitted successfully.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_user_report(UUID, TEXT, TEXT, TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_user_report(UUID, TEXT, TEXT, TEXT, UUID) TO authenticated;


-- ----------------------------------------------------------------------------
-- 5. Basic Moderation Management: Roles, Queries & Actions
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.moderators (
    user_id    UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.moderators ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "moderators_select_admin" ON public.moderators;
CREATE POLICY "moderators_select_admin"
    ON public.moderators FOR SELECT
    USING (
        auth.uid() = user_id 
        OR (COALESCE(auth.jwt()->'app_metadata'->>'role', '') IN ('admin', 'moderator'))
    );

DROP FUNCTION IF EXISTS public.is_moderator();

CREATE OR REPLACE FUNCTION public.is_moderator()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT (
        COALESCE((auth.jwt()->'app_metadata'->>'role' IN ('admin', 'moderator')), FALSE)
        OR EXISTS (SELECT 1 FROM public.moderators WHERE user_id = auth.uid())
    );
$$;

REVOKE ALL ON FUNCTION public.is_moderator() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_moderator() TO authenticated;


DROP FUNCTION IF EXISTS public.get_moderation_reports(TEXT);

CREATE OR REPLACE FUNCTION public.get_moderation_reports(
    p_status TEXT DEFAULT 'pending'
)
RETURNS TABLE (
    report_id             UUID,
    reported_user_id      UUID,
    reported_name         TEXT,
    reported_avatar       TEXT,
    reported_content_type TEXT,
    reported_content_id   UUID,
    reason                TEXT,
    description           TEXT,
    status                TEXT,
    created_at            TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT public.is_moderator() THEN
        RAISE EXCEPTION 'Access denied: moderator privileges required.';
    END IF;

    RETURN QUERY
    SELECT
        r.id AS report_id,
        r.reported_user_id,
        COALESCE(p.display_name, 'MELSAVA Member') AS reported_name,
        COALESCE(p.avatar_url, '') AS reported_avatar,
        r.reported_content_type,
        r.reported_content_id,
        r.reason,
        r.description,
        r.status::TEXT,
        r.created_at
    FROM public.reports r
    JOIN public.profiles p ON p.id = r.reported_user_id
    WHERE (p_status = 'all' OR r.status::TEXT = p_status)
    ORDER BY r.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_moderation_reports(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_moderation_reports(TEXT) TO authenticated;


DROP FUNCTION IF EXISTS public.resolve_moderation_report(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.resolve_moderation_report(
    p_report_id  UUID,
    p_new_status TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT public.is_moderator() THEN
        RAISE EXCEPTION 'Access denied: moderator privileges required.';
    END IF;

    UPDATE public.reports
       SET status = p_new_status::public.report_status,
           resolved_at = now()
     WHERE id = p_report_id;

    RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_moderation_report(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_moderation_report(UUID, TEXT) TO authenticated;


DROP FUNCTION IF EXISTS public.apply_moderation_action(UUID, TEXT, TEXT, UUID, TIMESTAMPTZ);

CREATE OR REPLACE FUNCTION public.apply_moderation_action(
    p_user_id     UUID,
    p_action_type TEXT,
    p_reason      TEXT,
    p_report_id   UUID DEFAULT NULL,
    p_expires_at  TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_mod_id    UUID := auth.uid();
    v_action_id UUID;
BEGIN
    IF NOT public.is_moderator() THEN
        RAISE EXCEPTION 'Access denied: moderator privileges required.';
    END IF;

    INSERT INTO public.moderation_actions (
        user_id,
        action_type,
        reason,
        performed_by,
        created_at,
        expires_at
    )
    VALUES (
        p_user_id,
        p_action_type::public.moderation_action_type,
        TRIM(p_reason),
        v_mod_id,
        now(),
        p_expires_at
    )
    RETURNING id INTO v_action_id;

    -- Apply suspension immediately if action is suspension or ban
    IF p_action_type IN ('suspension', 'ban') THEN
        UPDATE public.profiles
           SET is_suspended = TRUE,
               updated_at = now()
         WHERE id = p_user_id;
    END IF;

    -- Resolve report if associated
    IF p_report_id IS NOT NULL THEN
        UPDATE public.reports
           SET status = 'resolved',
               resolved_at = now()
         WHERE id = p_report_id;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'action_id', v_action_id,
        'message', 'Moderation action applied.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.apply_moderation_action(UUID, TEXT, TEXT, UUID, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.apply_moderation_action(UUID, TEXT, TEXT, UUID, TIMESTAMPTZ) TO authenticated;


-- ----------------------------------------------------------------------------
-- 6. Permanent Account Deletion RPC
-- ----------------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.delete_user_account_permanent(TEXT);

CREATE OR REPLACE FUNCTION public.delete_user_account_permanent(
    p_confirmation TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    IF TRIM(p_confirmation) != 'DELETE' THEN
        RAISE EXCEPTION 'Confirmation keyword "DELETE" required.';
    END IF;

    -- Clean up blocks and reports
    DELETE FROM public.blocks WHERE blocker_id = v_uid OR blocked_id = v_uid;
    DELETE FROM public.reports WHERE reporter_id = v_uid OR reported_user_id = v_uid;
    DELETE FROM public.moderation_actions WHERE user_id = v_uid;

    -- Delete public.profiles row which cascades across foreign keys
    DELETE FROM public.profiles WHERE id = v_uid;

    -- Delete credentials from auth.users (if accessible via security definer)
    BEGIN
        DELETE FROM auth.users WHERE id = v_uid;
    EXCEPTION WHEN OTHERS THEN
        -- Handled by Edge Function Admin API if permission is restricted
    END;

    RETURN jsonb_build_object(
        'success', TRUE,
        'status', 'deleted',
        'message', 'Account permanently deleted.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user_account_permanent(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account_permanent(TEXT) TO authenticated;
