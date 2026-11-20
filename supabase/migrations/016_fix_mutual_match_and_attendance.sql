-- ============================================================================
-- Migration 016: Fix Mutual Match RPC, Attendance & Notification Schema
-- Description:
--   1. Ensures `type` column exists on `conversations`
--   2. Ensures `body` and `payload` columns exist on `app_notifications`
--   3. Updates `complete_experience_and_mark_attendance` to allow flexible,
--      realistic event completion (up to 24h prior / anytime during or after event)
--   4. Fixes `submit_post_experience_choices` RPC:
--      - Removes invalid cast `::public.connection_type` (it is a TEXT column)
--      - Corrects insertion into `app_notifications` for both partner and caller
--      - Ensures seamless conversation and connection creation
-- ============================================================================

-- 1. Schema alignment for conversations & app_notifications
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'direct';

ALTER TABLE public.app_notifications ADD COLUMN IF NOT EXISTS body TEXT;
ALTER TABLE public.app_notifications ADD COLUMN IF NOT EXISTS payload JSONB DEFAULT '{}'::jsonb;

-- Populate body if empty
UPDATE public.app_notifications SET body = message WHERE body IS NULL;

-- 2. Updated complete_experience_and_mark_attendance
DROP FUNCTION IF EXISTS public.complete_experience_and_mark_attendance(UUID, UUID[]);

CREATE OR REPLACE FUNCTION public.complete_experience_and_mark_attendance(
    p_experience_id     UUID,
    p_attended_user_ids UUID[] DEFAULT '{}'
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
    v_current_attended INTEGER := 0;
    v_attended_count   INTEGER := 0;
    v_invalid_ids      UUID[];
BEGIN
    -- 1. Authenticate caller
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required to complete an experience.';
    END IF;

    -- 2. Lock and retrieve experience details
    SELECT host_id, status, starts_at, ends_at, duration_minutes
      INTO v_host_id, v_status, v_starts_at, v_ends_at, v_duration
      FROM public.experiences
     WHERE id = p_experience_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Experience not found: %', p_experience_id;
    END IF;

    -- 3. Authorization check
    IF v_host_id != v_uid AND NOT public.is_moderator() THEN
        RAISE EXCEPTION 'Unauthorized: only the host or a moderator can mark attendance.';
    END IF;

    -- 4. Idempotent check
    IF v_status = 'completed' THEN
        SELECT COUNT(*) INTO v_current_attended
          FROM public.experience_members
         WHERE experience_id = p_experience_id AND status = 'attended';

        RETURN jsonb_build_object(
            'success', TRUE,
            'already_completed', TRUE,
            'experience_id', p_experience_id,
            'status', 'completed',
            'attended_count', v_current_attended,
            'message', 'Experience attendance was already confirmed and finalized.'
        );
    END IF;

    -- 5. Time check: Prevent completing more than 24 hours before scheduled start
    IF v_starts_at IS NOT NULL AND v_now < (v_starts_at - interval '24 hours') THEN
        RAISE EXCEPTION 'Cannot complete experience more than 24 hours before its scheduled start time.';
    END IF;

    -- 6. Validate attendee array if supplied
    IF p_attended_user_ids IS NOT NULL AND array_length(p_attended_user_ids, 1) > 0 THEN
        IF (SELECT COUNT(*) FROM unnest(p_attended_user_ids)) != (SELECT COUNT(DISTINCT x) FROM unnest(p_attended_user_ids) x) THEN
            RAISE EXCEPTION 'Duplicate attendee IDs in attendance submission.';
        END IF;

        -- Check that every ID belongs to an existing member (joined or attended)
        SELECT array_agg(att_id)
          INTO v_invalid_ids
          FROM unnest(p_attended_user_ids) att_id
         WHERE NOT EXISTS (
             SELECT 1 FROM public.experience_members em
              WHERE em.experience_id = p_experience_id
                AND em.user_id = att_id
         );

        IF v_invalid_ids IS NOT NULL AND array_length(v_invalid_ids, 1) > 0 THEN
            RAISE EXCEPTION 'Invalid attendee ID(s): % are not members of this experience.', v_invalid_ids;
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
           AND user_id = ANY(p_attended_user_ids);

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


-- 3. Updated submit_post_experience_choices
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

        -- Create mutual connection idempotently (TEXT connection_type)
        INSERT INTO public.connections (
            user_a_id, user_b_id, connection_type, experience_id, created_at
        )
        VALUES (
            v_user_a, v_user_b, v_choice_type, p_experience_id, v_now
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
            user_id, title, message, body, type, payload, connection_id, experience_id, created_at
        )
        VALUES (
            v_chosen_id,
            'It’s a Mutual Match! 🎉',
            format('You and %s mutually chose to reconnect as %s from "%s"!',
                   COALESCE(v_my_name, 'a participant'), v_type_label, v_exp_title),
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
            v_conn_id,
            p_experience_id,
            v_now
        );

        -- Send notification to caller as well
        INSERT INTO public.app_notifications (
            user_id, title, message, body, type, payload, connection_id, experience_id, created_at
        )
        VALUES (
            v_uid,
            'It’s a Mutual Match! 🎉',
            format('You and %s mutually chose to reconnect as %s from "%s"!',
                   COALESCE(v_partner_name, 'a participant'), v_type_label, v_exp_title),
            format('You and %s mutually chose to reconnect as %s from "%s"!',
                   COALESCE(v_partner_name, 'a participant'), v_type_label, v_exp_title),
            'mutual_match',
            jsonb_build_object(
                'connection_id', v_conn_id,
                'conversation_id', v_conv_id,
                'partner_id', v_chosen_id,
                'experience_id', p_experience_id,
                'connection_type', v_choice_type
            ),
            v_conn_id,
            p_experience_id,
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
