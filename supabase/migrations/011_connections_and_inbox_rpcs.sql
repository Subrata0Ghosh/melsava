-- ============================================================================
-- MELSAVA - Live Connections & Inbox RPCs
-- Migration: 011_connections_and_inbox_rpcs.sql
-- Description:
--   1. `get_user_connections()`: Returns all mutual connections with partner details,
--      conversation id, experience details, and latest message preview.
--   2. `get_user_inbox_threads()`: Returns active conversations for the user with
--      partner info, unread message counts, and timestamps.
--   3. `send_conversation_message()`: Sends a message within a conversation securely.
--   4. `get_conversation_messages()`: Fetches chronological messages and marks incoming as read.
--   5. `get_or_create_conversation_for_connection()`: Ensures a direct conversation thread exists.
-- ============================================================================

-- 1. Get User Connections
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
    created_at           TIMESTAMPTZ,
    compatibility_score  INT
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
        SELECT DISTINCT ON (c.id)
            c.id AS conversation_id,
            m.content AS message_text,
            m.created_at AS message_time
        FROM public.conversations c
        JOIN public.messages m ON m.conversation_id = c.id
        ORDER BY c.id, m.created_at DESC
    )
    SELECT
        c.id AS connection_id,
        conv.id AS conversation_id,
        p.id AS partner_id,
        COALESCE(p.display_name, 'MELSAVA Member') AS partner_name,
        COALESCE(p.avatar_url, '') AS partner_avatar,
        COALESCE(p.bio, '') AS partner_bio,
        c.connection_type,
        c.experience_id,
        COALESCE(e.title, 'Shared Experience') AS experience_title,
        COALESCE(lm.message_text, '') AS last_message,
        lm.message_time AS last_message_at,
        c.created_at,
        92::INT AS compatibility_score
    FROM public.connections c
    LEFT JOIN public.experiences e ON e.id = c.experience_id
    JOIN public.profiles p ON p.id = (
        CASE WHEN c.user_a_id = v_uid THEN c.user_b_id ELSE c.user_a_id END
    )
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


-- 2. Get User Inbox Threads
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
        COALESCE(c.connection_type, 'friendship') AS connection_type,
        COALESCE(e.title, 'Shared Experience') AS experience_title,
        COALESCE(lm.message_text, 'Say hi to your new connection!') AS last_message,
        COALESCE(lm.message_time, conv.created_at) AS last_message_at,
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
    ORDER BY COALESCE(lm.message_time, conv.created_at) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_inbox_threads() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_inbox_threads() TO authenticated;


-- 3. Send Conversation Message
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
    v_uid UUID := auth.uid();
    v_msg_id UUID;
    v_now TIMESTAMPTZ := now();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Ensure caller is a member of the conversation
    IF NOT EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_id = p_conversation_id AND user_id = v_uid
    ) THEN
        RAISE EXCEPTION 'Unauthorized conversation member';
    END IF;

    INSERT INTO public.messages (conversation_id, sender_id, content, created_at)
    VALUES (p_conversation_id, v_uid, p_content, v_now)
    RETURNING id INTO v_msg_id;

    UPDATE public.conversations
       SET updated_at = v_now
     WHERE id = p_conversation_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message_id', v_msg_id,
        'created_at', v_now
    );
END;
$$;

REVOKE ALL ON FUNCTION public.send_conversation_message(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_conversation_message(UUID, TEXT) TO authenticated;


-- 4. Get Conversation Messages
CREATE OR REPLACE FUNCTION public.get_conversation_messages(
    p_conversation_id UUID
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
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Ensure caller is a member of the conversation
    IF NOT EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_id = p_conversation_id AND user_id = v_uid
    ) THEN
        RAISE EXCEPTION 'Unauthorized conversation member';
    END IF;

    -- Mark incoming messages as read
    UPDATE public.messages
       SET is_read = TRUE
     WHERE conversation_id = p_conversation_id
       AND sender_id != v_uid
       AND is_read = FALSE;

    RETURN QUERY
    SELECT
        m.id AS message_id,
        m.sender_id,
        m.content,
        m.is_read,
        m.created_at,
        (m.sender_id = v_uid) AS is_me
    FROM public.messages m
    WHERE m.conversation_id = p_conversation_id
    ORDER BY m.created_at ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_conversation_messages(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_conversation_messages(UUID) TO authenticated;


-- 5. Get or Create Conversation for Connection
CREATE OR REPLACE FUNCTION public.get_or_create_conversation_for_connection(
    p_connection_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_conn RECORD;
    v_conv_id UUID;
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

    -- Look for existing conversation
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE connection_id = p_connection_id
    LIMIT 1;

    IF v_conv_id IS NULL THEN
        INSERT INTO public.conversations (type, connection_id)
        VALUES ('direct', p_connection_id)
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
