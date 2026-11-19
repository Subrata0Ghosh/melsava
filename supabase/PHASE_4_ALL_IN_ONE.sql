-- ============================================================================
-- MELSAVA — Phase 3 Hardening Migration
-- Migration: 012_phase3_hardening.sql
-- Description:
--   1. Hardens `complete_experience_and_mark_attendance()`:
--      - Requires authenticated host.
--      - Locks experience row with FOR UPDATE.
--      - Rejects cancelled and draft experiences.
--      - Verifies scheduled duration has finished (starts_at + duration_minutes or ends_at).
--      - Rejects invalid attendee IDs (rejects duplicates and non-joined members).
--      - Ensures idempotency: safe return if already completed without altering finalized records.
--   2. Hardens `submit_post_experience_choices()`:
--      - Locks parent experience row with FOR UPDATE to serialize concurrent reciprocal submissions.
--      - Validates all submitted participant IDs: rejects self-selection, non-attendees, duplicates.
--      - Rejects invalid choice types instead of silently converting them.
--      - Permits empty selection only when no eligible peers attended.
--      - Prevents duplicate connections, conversations, or notifications on retries.
--      - Preserves exact compatibility rules (Friendship=Friendship, Activity=Activity, Dating=Dating).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Hardened complete_experience_and_mark_attendance
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.complete_experience_and_mark_attendance(UUID, UUID[]);

CREATE OR REPLACE FUNCTION public.complete_experience_and_mark_attendance(
    p_experience_id      UUID,
    p_attended_user_ids  UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid              UUID := auth.uid();
    v_host_id          UUID;
    v_status           public.experience_status;
    v_starts_at        TIMESTAMPTZ;
    v_ends_at          TIMESTAMPTZ;
    v_duration         INTEGER;
    v_now              TIMESTAMPTZ := now();
    v_end_time         TIMESTAMPTZ;
    v_attended_count   INTEGER := 0;
    v_invalid_ids      UUID[];
    v_current_attended INTEGER;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    -- 1. Lock experience row to verify ownership, status, and times
    SELECT host_id, status, starts_at, ends_at, duration_minutes
      INTO v_host_id, v_status, v_starts_at, v_ends_at, v_duration
      FROM public.experiences
     WHERE id = p_experience_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Experience not found: %', p_experience_id;
    END IF;

    -- 2. Verify caller is host
    IF v_host_id != v_uid THEN
        RAISE EXCEPTION 'Only the experience host can confirm attendance.';
    END IF;

    -- 3. Reject cancelled and draft experiences
    IF v_status = 'cancelled' THEN
        RAISE EXCEPTION 'Cannot mark attendance for a cancelled experience.';
    END IF;

    IF v_status = 'draft' THEN
        RAISE EXCEPTION 'Cannot mark attendance for a draft experience.';
    END IF;

    -- 4. Idempotency: If already completed, return safe status without modifying records
    IF v_status = 'completed' THEN
        SELECT COUNT(*)
          INTO v_current_attended
          FROM public.experience_members
         WHERE experience_id = p_experience_id
           AND status = 'attended';

        RETURN jsonb_build_object(
            'success', TRUE,
            'already_completed', TRUE,
            'experience_id', p_experience_id,
            'status', 'completed',
            'attended_count', v_current_attended,
            'message', 'Experience attendance was already confirmed and finalized.'
        );
    END IF;

    -- 5. Calculate and verify scheduled end time
    v_end_time := COALESCE(
        v_ends_at,
        CASE
            WHEN v_starts_at IS NOT NULL AND v_duration IS NOT NULL AND v_duration > 0
            THEN v_starts_at + (v_duration || ' minutes')::interval
            ELSE NULL
        END
    );

    IF v_end_time IS NULL THEN
        RAISE EXCEPTION 'Experience duration information is missing; cannot complete prematurely.';
    END IF;

    IF v_now < v_end_time THEN
        RAISE EXCEPTION 'Cannot complete experience before its scheduled end time.';
    END IF;

    -- 6. Validate attendee array if supplied
    IF p_attended_user_ids IS NOT NULL AND array_length(p_attended_user_ids, 1) > 0 THEN
        -- Check for duplicate IDs
        IF (SELECT COUNT(*) FROM unnest(p_attended_user_ids)) != (SELECT COUNT(DISTINCT x) FROM unnest(p_attended_user_ids) x) THEN
            RAISE EXCEPTION 'Duplicate attendee IDs in attendance submission.';
        END IF;

        -- Validate that every ID belongs to an eligible joined membership
        SELECT array_agg(att_id)
          INTO v_invalid_ids
          FROM unnest(p_attended_user_ids) att_id
         WHERE NOT EXISTS (
             SELECT 1 FROM public.experience_members em
              WHERE em.experience_id = p_experience_id
                AND em.user_id = att_id
                AND em.status = 'joined'
         );

        IF v_invalid_ids IS NOT NULL AND array_length(v_invalid_ids, 1) > 0 THEN
            RAISE EXCEPTION 'Invalid attendee ID(s): % are not eligible joined members.', v_invalid_ids;
        END IF;
    END IF;

    -- 7. Update experience status to completed
    UPDATE public.experiences
       SET status = 'completed'
     WHERE id = p_experience_id;

    -- 8. Mark eligible attendees as 'attended'
    IF p_attended_user_ids IS NOT NULL AND array_length(p_attended_user_ids, 1) > 0 THEN
        UPDATE public.experience_members
           SET status = 'attended'
         WHERE experience_id = p_experience_id
           AND user_id = ANY(p_attended_user_ids)
           AND status = 'joined';

        GET DIAGNOSTICS v_attended_count = ROW_COUNT;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'already_completed', FALSE,
        'experience_id', p_experience_id,
        'status', 'completed',
        'attended_count', v_attended_count
    );
END;
$$;

REVOKE ALL ON FUNCTION public.complete_experience_and_mark_attendance(UUID, UUID[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_experience_and_mark_attendance(UUID, UUID[]) TO authenticated;


-- ----------------------------------------------------------------------------
-- 2. Hardened submit_post_experience_choices
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.submit_post_experience_choices(UUID, JSONB);

CREATE OR REPLACE FUNCTION public.submit_post_experience_choices(
    p_experience_id UUID,
    p_choices       JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid               UUID := auth.uid();
    v_exp_status        public.experience_status;
    v_exp_title         TEXT;
    v_attended          BOOLEAN := FALSE;
    v_already_submitted BOOLEAN := FALSE;
    v_now               TIMESTAMPTZ := now();
    v_choice_elem       JSONB;
    v_chosen_id         UUID;
    v_choice_type       TEXT;
    v_partner_choice    TEXT;
    v_partner_submitted BOOLEAN := FALSE;
    v_user_a            UUID;
    v_user_b            UUID;
    v_conn_id           UUID;
    v_conv_id           UUID;
    v_partner_name      TEXT;
    v_partner_avatar    TEXT;
    v_my_name           TEXT;
    v_type_label        TEXT;
    v_new_connections   JSONB := '[]'::jsonb;
    v_inserted_choices  INTEGER := 0;
    v_peer_count        INTEGER := 0;
    v_seen_ids          UUID[] := '{}';
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required to submit connection choices.';
    END IF;

    -- 1. Lock the parent experience row to serialize concurrent reciprocal submissions
    SELECT status, title
      INTO v_exp_status, v_exp_title
      FROM public.experiences
     WHERE id = p_experience_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Experience not found: %', p_experience_id;
    END IF;

    IF v_exp_status != 'completed' THEN
        RAISE EXCEPTION 'Reconnect choices are available only after an experience is completed.';
    END IF;

    -- 2. Verify caller is confirmed attended member
    SELECT EXISTS (
        SELECT 1 FROM public.experience_members
        WHERE experience_id = p_experience_id
          AND user_id = v_uid
          AND status = 'attended'
    ) INTO v_attended;

    IF NOT v_attended THEN
        RAISE EXCEPTION 'This reconnect activity is available only to confirmed attendees.';
    END IF;

    -- 3. Idempotent guard: Check if already submitted
    SELECT EXISTS (
        SELECT 1 FROM public.post_experience_submissions
        WHERE experience_id = p_experience_id
          AND user_id = v_uid
    ) INTO v_already_submitted;

    IF v_already_submitted THEN
        -- Return any existing mutual connections already created for this user and experience
        SELECT jsonb_agg(
            jsonb_build_object(
                'connection_id', c.id,
                'conversation_id', conv.id,
                'partner_id', p.id,
                'partner_name', p.display_name,
                'partner_avatar', COALESCE(p.avatar_url, ''),
                'connection_type', c.connection_type,
                'connection_type_label', CASE
                    WHEN c.connection_type = 'explore_dating' THEN 'Dating Connection'
                    WHEN c.connection_type = 'activity_partner' THEN 'Activity Partner'
                    ELSE 'New Friend'
                END,
                'experience_title', v_exp_title
            )
        )
        INTO v_new_connections
        FROM public.connections c
        JOIN public.conversations conv ON conv.connection_id = c.id
        JOIN public.profiles p ON p.id = (CASE WHEN c.user_a_id = v_uid THEN c.user_b_id ELSE c.user_a_id END)
        WHERE c.experience_id = p_experience_id
          AND (c.user_a_id = v_uid OR c.user_b_id = v_uid);

        RETURN jsonb_build_object(
            'submitted', TRUE,
            'already_submitted', TRUE,
            'message', 'Your choices for this experience have already been submitted.',
            'mutual_connections', COALESCE(v_new_connections, '[]'::jsonb)
        );
    END IF;

    -- Caller display name for notification
    SELECT display_name INTO v_my_name FROM public.profiles WHERE id = v_uid;

    -- 4. Count eligible attended peers
    SELECT COUNT(*)
      INTO v_peer_count
      FROM public.experience_members
     WHERE experience_id = p_experience_id
       AND user_id != v_uid
       AND status = 'attended';

    -- Permit empty selection only when there are genuinely no eligible peers
    IF (p_choices IS NULL OR jsonb_array_length(p_choices) = 0) THEN
        IF v_peer_count > 0 THEN
            RAISE EXCEPTION 'Choices cannot be empty when eligible peers attended the experience.';
        END IF;
    END IF;

    -- 5. Validate and record choices
    IF p_choices IS NOT NULL AND jsonb_array_length(p_choices) > 0 THEN
        FOR v_choice_elem IN SELECT * FROM jsonb_array_elements(p_choices)
        LOOP
            IF v_choice_elem->>'chosen_id' IS NULL THEN
                RAISE EXCEPTION 'Missing chosen_id in submission payload.';
            END IF;

            v_chosen_id := (v_choice_elem->>'chosen_id')::UUID;
            v_choice_type := TRIM(LOWER(COALESCE(v_choice_elem->>'choice_type', '')));

            -- Reject self-selection
            IF v_chosen_id = v_uid THEN
                RAISE EXCEPTION 'Cannot select yourself for connection.';
            END IF;

            -- Reject duplicate entries in choices payload
            IF v_chosen_id = ANY(v_seen_ids) THEN
                RAISE EXCEPTION 'Duplicate connection choice for participant %.', v_chosen_id;
            END IF;
            v_seen_ids := array_append(v_seen_ids, v_chosen_id);

            -- Reject participants who did not attend this experience
            IF NOT EXISTS (
                SELECT 1 FROM public.experience_members
                WHERE experience_id = p_experience_id
                  AND user_id = v_chosen_id
                  AND status = 'attended'
            ) THEN
                RAISE EXCEPTION 'Invalid participant %: did not attend this experience.', v_chosen_id;
            END IF;

            -- Reject invalid choice types
            IF v_choice_type NOT IN ('friendship', 'activity_partner', 'explore_dating', 'no_connection') THEN
                RAISE EXCEPTION 'Invalid choice type: %.', v_choice_type;
            END IF;

            -- Insert or update choice
            INSERT INTO public.post_experience_choices (
                experience_id, chooser_id, chosen_id, choice_type, created_at
            )
            VALUES (
                p_experience_id, v_uid, v_chosen_id, v_choice_type::public.choice_type, v_now
            )
            ON CONFLICT (experience_id, chooser_id, chosen_id) DO UPDATE SET
                choice_type = EXCLUDED.choice_type,
                created_at = v_now;

            v_inserted_choices := v_inserted_choices + 1;
        END LOOP;
    END IF;

    -- 6. Record final submission
    INSERT INTO public.post_experience_submissions (
        experience_id, user_id, submitted_at
    )
    VALUES (
        p_experience_id, v_uid, v_now
    )
    ON CONFLICT (experience_id, user_id) DO NOTHING;

    -- 7. Evaluate exact mutual matching against partner submissions
    --    Only creates a connection when:
    --    - Both users submitted their final choices
    --    - User A chose B AND User B chose A
    --    - EXACT MATCH: (Friendship=Friendship, Activity=Activity, Dating=Dating)
    --    - Neither chose 'no_connection'
    --    - Neither user blocked the other
    --    - Neither user is suspended
    FOR v_chosen_id, v_choice_type IN
        SELECT chosen_id, choice_type::TEXT
          FROM public.post_experience_choices
         WHERE experience_id = p_experience_id
           AND chooser_id = v_uid
           AND choice_type != 'no_connection'
    LOOP
        -- Check if partner submitted their final choices
        SELECT EXISTS (
            SELECT 1 FROM public.post_experience_submissions
            WHERE experience_id = p_experience_id
              AND user_id = v_chosen_id
        ) INTO v_partner_submitted;

        IF NOT v_partner_submitted THEN
            CONTINUE;
        END IF;

        -- Check partner's choice for current user
        SELECT choice_type::TEXT INTO v_partner_choice
          FROM public.post_experience_choices
         WHERE experience_id = p_experience_id
           AND chooser_id = v_chosen_id
           AND chosen_id = v_uid;

        IF v_partner_choice IS NULL OR v_partner_choice = 'no_connection' THEN
            CONTINUE;
        END IF;

        -- STRICT EXACT MATCH: intentions must be identical
        IF v_choice_type != v_partner_choice THEN
            CONTINUE;
        END IF;

        -- Check neither blocked the other
        IF EXISTS (
            SELECT 1 FROM public.blocks
            WHERE (blocker_id = v_uid AND blocked_id = v_chosen_id)
               OR (blocker_id = v_chosen_id AND blocked_id = v_uid)
        ) THEN
            CONTINUE;
        END IF;

        -- Check neither is suspended
        IF EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id IN (v_uid, v_chosen_id) AND is_suspended = TRUE
        ) THEN
            CONTINUE;
        END IF;

        -- Canonical user ordering (user_a < user_b)
        IF v_uid < v_chosen_id THEN
            v_user_a := v_uid;
            v_user_b := v_chosen_id;
        ELSE
            v_user_a := v_chosen_id;
            v_user_b := v_uid;
        END IF;

        -- Create mutual connection idempotently
        INSERT INTO public.connections (
            user_a_id, user_b_id, connection_type, experience_id, created_at
        )
        VALUES (
            v_user_a, v_user_b, v_choice_type::public.connection_type, p_experience_id, v_now
        )
        ON CONFLICT (user_a_id, user_b_id) DO UPDATE SET
            connection_type = EXCLUDED.connection_type
        RETURNING id INTO v_conn_id;

        -- Create associated conversation
        INSERT INTO public.conversations (
            type, connection_id, created_at, updated_at
        )
        VALUES (
            'direct', v_conn_id, v_now, v_now
        )
        ON CONFLICT (connection_id) DO UPDATE SET
            updated_at = v_now
        RETURNING id INTO v_conv_id;

        -- Add conversation members
        INSERT INTO public.conversation_members (conversation_id, user_id)
        VALUES
            (v_conv_id, v_user_a),
            (v_conv_id, v_user_b)
        ON CONFLICT (conversation_id, user_id) DO NOTHING;

        -- Partner profile info
        SELECT display_name, avatar_url
          INTO v_partner_name, v_partner_avatar
          FROM public.profiles
         WHERE id = v_chosen_id;

        -- User-facing label
        v_type_label := CASE
            WHEN v_choice_type = 'explore_dating' THEN 'Dating Connection'
            WHEN v_choice_type = 'activity_partner' THEN 'Activity Partner'
            ELSE 'New Friend'
        END;

        -- Send notification to partner
        INSERT INTO public.app_notifications (
            user_id, title, body, type, payload, created_at
        )
        VALUES (
            v_chosen_id,
            'It’s a Mutual Match! 🎉',
            format('You and %s mutually chose to reconnect as %s from "%s"!',
                   COALESCE(v_my_name, 'a participant'), v_type_label, v_exp_title),
            'mutual_match',
            jsonb_build_object(
                'connection_id', v_conn_id,
                'conversation_id', v_conv_id,
                'partner_id', v_uid,
                'experience_id', p_experience_id,
                'connection_type', v_choice_type
            ),
            v_now
        );

        -- Accumulate in response payload
        v_new_connections := v_new_connections || jsonb_build_object(
            'connection_id', v_conn_id,
            'conversation_id', v_conv_id,
            'partner_id', v_chosen_id,
            'partner_name', v_partner_name,
            'partner_avatar', COALESCE(v_partner_avatar, ''),
            'connection_type', v_choice_type,
            'connection_type_label', v_type_label,
            'experience_title', v_exp_title
        );
    END LOOP;

    RETURN jsonb_build_object(
        'submitted', TRUE,
        'already_submitted', FALSE,
        'message', 'Choices recorded successfully.',
        'mutual_connections', v_new_connections
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_post_experience_choices(UUID, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_post_experience_choices(UUID, JSONB) TO authenticated;
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
