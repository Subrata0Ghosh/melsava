-- ============================================================================
-- MELSAVA — Phase 3: Real Attendance, Private Mutual Choice & Connection Creation
-- Migration: 009_phase3_attendance_and_mutual_choices.sql
-- Description:
--   1. Creates `post_experience_submissions` table to track final submitted status
--      per user per experience (idempotent, prevents resubmission & race conditions).
--   2. Creates `app_notifications` table for real in-app mutual connection alerts.
--   3. Tightens RLS policies on `post_experience_choices` and `connections`.
--   4. Adds `complete_experience_and_mark_attendance()` RPC for host-only attendance.
--   5. Adds `get_host_joined_participants()` RPC for host review of attendees.
--   6. Adds `fetch_eligible_reconnect_attendees()` RPC (zero PII, only attended peers).
--   7. Adds `fetch_reconnect_submission_status()` RPC.
--   8. Adds atomic, consent-first `submit_post_experience_choices()` RPC with exact
--      intention matching (Friendship=Friendship, Dating=Dating), mutual validation,
--      canonical connection & conversation creation, and in-app notifications.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Table: post_experience_submissions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.post_experience_submissions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experience_id UUID NOT NULL REFERENCES public.experiences(id) ON DELETE CASCADE,
    user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    submitted_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (experience_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_pes_exp_user
    ON public.post_experience_submissions (experience_id, user_id);

ALTER TABLE public.post_experience_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pes_select_own" ON public.post_experience_submissions;
CREATE POLICY "pes_select_own"
    ON public.post_experience_submissions FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 2. Table: app_notifications
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_notifications (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type              TEXT NOT NULL,
    notification_type TEXT GENERATED ALWAYS AS (type) STORED,
    title             TEXT NOT NULL,
    message           TEXT NOT NULL,
    connection_id     UUID REFERENCES public.connections(id) ON DELETE SET NULL,
    experience_id     UUID REFERENCES public.experiences(id) ON DELETE SET NULL,
    read_at           TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
    ON public.app_notifications (user_id, created_at DESC);

ALTER TABLE public.app_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select_own" ON public.app_notifications;
CREATE POLICY "notifications_select_own"
    ON public.app_notifications FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_update_own" ON public.app_notifications;
CREATE POLICY "notifications_update_own"
    ON public.app_notifications FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 3. Tighten RLS on `post_experience_choices`
--    All choices must be submitted via the atomic RPC to ensure attended status
--    and consent validation.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "post_experience_choices_insert" ON public.post_experience_choices;
DROP POLICY IF EXISTS "post_experience_choices_select" ON public.post_experience_choices;

CREATE POLICY "post_experience_choices_select_own"
    ON public.post_experience_choices FOR SELECT
    TO authenticated
    USING (chooser_id = auth.uid());

-- Direct inserts/updates disallowed from clients; handled by submit_post_experience_choices()

-- ----------------------------------------------------------------------------
-- 4. RPC: Host Review of Joined Participants (`get_host_joined_participants`)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_host_joined_participants(
    p_experience_id UUID
)
RETURNS TABLE (
    user_id       UUID,
    display_name  TEXT,
    avatar_url    TEXT,
    bio           TEXT,
    member_status TEXT,
    joined_at     TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        p.id AS user_id,
        p.display_name,
        p.avatar_url,
        p.bio,
        em.status::TEXT AS member_status,
        em.joined_at
    FROM public.experiences e
    JOIN public.experience_members em ON em.experience_id = e.id
    JOIN public.profiles p ON p.id = em.user_id
    WHERE e.id = p_experience_id
      AND e.host_id = auth.uid()
      AND em.status IN ('joined', 'attended')
    ORDER BY em.joined_at ASC;
$$;

REVOKE ALL ON FUNCTION public.get_host_joined_participants(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_host_joined_participants(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 4.1. RPC: Live Meetup Circle Participants (`get_experience_circle_participants`)
--      Allows joined members and the host to see actual session participants.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_experience_circle_participants(
    p_experience_id UUID
)
RETURNS TABLE (
    user_id       UUID,
    display_name  TEXT,
    avatar_url    TEXT,
    bio           TEXT,
    role          TEXT,
    joined_at     TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_host_id   UUID;
    v_is_member BOOLEAN;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT host_id INTO v_host_id
    FROM public.experiences
    WHERE id = p_experience_id;

    IF v_host_id IS NULL THEN
        RAISE EXCEPTION 'Experience not found';
    END IF;

    -- Caller must be host or active joined member
    SELECT EXISTS (
        SELECT 1 FROM public.experience_members
        WHERE experience_id = p_experience_id
          AND user_id = v_caller_id
          AND status IN ('joined', 'attended')
    ) INTO v_is_member;

    IF v_caller_id != v_host_id AND NOT v_is_member THEN
        RAISE EXCEPTION 'Only active joined participants and the host can view the meetup circle';
    END IF;

    -- Return Host first
    RETURN QUERY
    SELECT 
        p.id AS user_id,
        p.display_name,
        p.avatar_url,
        p.bio,
        'Host'::TEXT AS role,
        e.created_at AS joined_at
    FROM public.experiences e
    JOIN public.profiles p ON p.id = e.host_id
    WHERE e.id = p_experience_id
      AND NOT EXISTS (
          SELECT 1 FROM public.blocks b
          WHERE (b.blocker_id = v_caller_id AND b.blocked_id = p.id)
             OR (b.blocker_id = p.id AND b.blocked_id = v_caller_id)
      )

    UNION ALL

    -- Then return all joined attendees (excluding host if host is also member)
    SELECT 
        p.id AS user_id,
        p.display_name,
        p.avatar_url,
        p.bio,
        'Attendee'::TEXT AS role,
        em.joined_at
    FROM public.experience_members em
    JOIN public.profiles p ON p.id = em.user_id
    WHERE em.experience_id = p_experience_id
      AND em.status IN ('joined', 'attended')
      AND em.user_id != v_host_id
      AND NOT EXISTS (
          SELECT 1 FROM public.blocks b
          WHERE (b.blocker_id = v_caller_id AND b.blocked_id = p.id)
             OR (b.blocker_id = p.id AND b.blocked_id = v_caller_id)
      )
    ORDER BY joined_at ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_experience_circle_participants(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_experience_circle_participants(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 5. RPC: Host Attendance Confirmation (`complete_experience_and_mark_attendance`)
-- ----------------------------------------------------------------------------
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
    v_duration         INTEGER;
    v_now              TIMESTAMPTZ := now();
    v_attended_count   INTEGER := 0;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    -- Lock experience row to verify ownership and current status
    SELECT host_id, status, starts_at, duration_minutes
      INTO v_host_id, v_status, v_starts_at, v_duration
      FROM public.experiences
     WHERE id = p_experience_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Experience not found: %', p_experience_id;
    END IF;

    IF v_host_id != v_uid THEN
        RAISE EXCEPTION 'Only the experience host can confirm attendance.';
    END IF;

    IF v_status = 'cancelled' THEN
        RAISE EXCEPTION 'Cannot mark attendance for a cancelled experience.';
    END IF;

    IF v_status = 'draft' THEN
        RAISE EXCEPTION 'Cannot mark attendance for a draft experience.';
    END IF;

    -- Verify experience has started or passed
    IF v_starts_at IS NOT NULL AND v_starts_at > v_now THEN
        RAISE EXCEPTION 'Cannot complete experience before its scheduled start time.';
    END IF;

    -- Update experience status to completed
    UPDATE public.experiences
       SET status = 'completed'
     WHERE id = p_experience_id;

    -- Mark eligible attendees as 'attended'
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
        'experience_id', p_experience_id,
        'status', 'completed',
        'attended_count', v_attended_count
    );
END;
$$;

REVOKE ALL ON FUNCTION public.complete_experience_and_mark_attendance(UUID, UUID[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_experience_and_mark_attendance(UUID, UUID[]) TO authenticated;

-- ----------------------------------------------------------------------------
-- 6. RPC: Fetch Eligible Reconnect Attendees (`fetch_eligible_reconnect_attendees`)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fetch_eligible_reconnect_attendees(
    p_experience_id UUID
)
RETURNS TABLE (
    user_id           UUID,
    display_name      TEXT,
    avatar_url        TEXT,
    bio               TEXT,
    experience_title  TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid        UUID := auth.uid();
    v_exp_status public.experience_status;
    v_attended   BOOLEAN := FALSE;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    -- Verify experience is completed
    SELECT status INTO v_exp_status
      FROM public.experiences
     WHERE id = p_experience_id;

    IF v_exp_status != 'completed' THEN
        RETURN;
    END IF;

    -- Verify caller actually attended this experience
    SELECT EXISTS (
        SELECT 1 FROM public.experience_members
        WHERE experience_id = p_experience_id
          AND user_id = v_uid
          AND status = 'attended'
    ) INTO v_attended;

    IF NOT v_attended THEN
        RETURN;
    END IF;

    -- Return eligible attended peers (excluding self, blocked users, and suspended users)
    RETURN QUERY
    SELECT
        p.id AS user_id,
        p.display_name,
        p.avatar_url,
        p.bio,
        e.title AS experience_title
    FROM public.experience_members em
    JOIN public.experiences e ON e.id = em.experience_id
    JOIN public.profiles p ON p.id = em.user_id
    WHERE em.experience_id = p_experience_id
      AND em.user_id != v_uid
      AND em.status = 'attended'
      AND p.is_suspended = FALSE
      AND NOT EXISTS (
          SELECT 1 FROM public.blocks b
          WHERE (b.blocker_id = v_uid AND b.blocked_id = p.id)
             OR (b.blocker_id = p.id AND b.blocked_id = v_uid)
      )
    ORDER BY em.joined_at ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.fetch_eligible_reconnect_attendees(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fetch_eligible_reconnect_attendees(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 7. RPC: Fetch Reconnect Submission Status (`fetch_reconnect_submission_status`)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fetch_reconnect_submission_status(
    p_experience_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid            UUID := auth.uid();
    v_exp_status     public.experience_status;
    v_attended       BOOLEAN := FALSE;
    v_is_host        BOOLEAN := FALSE;
    v_submitted      BOOLEAN := FALSE;
    v_submitted_at   TIMESTAMPTZ;
BEGIN
    IF v_uid IS NULL THEN
        RETURN jsonb_build_object('authenticated', FALSE);
    END IF;

    SELECT status, (host_id = v_uid)
      INTO v_exp_status, v_is_host
      FROM public.experiences
     WHERE id = p_experience_id;

    SELECT EXISTS (
        SELECT 1 FROM public.experience_members
        WHERE experience_id = p_experience_id
          AND user_id = v_uid
          AND status = 'attended'
    ) INTO v_attended;

    SELECT EXISTS (
        SELECT 1 FROM public.post_experience_submissions
        WHERE experience_id = p_experience_id
          AND user_id = v_uid
    ), (
        SELECT submitted_at FROM public.post_experience_submissions
        WHERE experience_id = p_experience_id
          AND user_id = v_uid
    ) INTO v_submitted, v_submitted_at;

    RETURN jsonb_build_object(
        'authenticated', TRUE,
        'experience_status', v_exp_status::TEXT,
        'is_completed', (v_exp_status = 'completed'),
        'is_attended', v_attended,
        'is_host', v_is_host,
        'is_submitted', v_submitted,
        'submitted_at', v_submitted_at
    );
END;
$$;

REVOKE ALL ON FUNCTION public.fetch_reconnect_submission_status(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fetch_reconnect_submission_status(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 8. RPC: Private Submission & Exact Mutual Matching (`submit_post_experience_choices`)
-- ----------------------------------------------------------------------------
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
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required to submit connection choices.';
    END IF;

    -- 1. Check experience is completed
    SELECT status, title INTO v_exp_status, v_exp_title
      FROM public.experiences
     WHERE id = p_experience_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Experience not found.';
    END IF;

    IF v_exp_status != 'completed' THEN
        RAISE EXCEPTION 'Reconnect choices are available only after an experience is completed.';
    END IF;

    -- 2. Check caller is confirmed attended member
    SELECT EXISTS (
        SELECT 1 FROM public.experience_members
        WHERE experience_id = p_experience_id
          AND user_id = v_uid
          AND status = 'attended'
    ) INTO v_attended;

    IF NOT v_attended THEN
        RAISE EXCEPTION 'This reconnect activity is available only to confirmed attendees.';
    END IF;

    -- 3. Check duplicate submission (idempotent guard)
    SELECT EXISTS (
        SELECT 1 FROM public.post_experience_submissions
        WHERE experience_id = p_experience_id
          AND user_id = v_uid
    ) INTO v_already_submitted;

    IF v_already_submitted THEN
        RETURN jsonb_build_object(
            'already_submitted', TRUE,
            'message', 'Your choices for this experience have already been submitted.',
            'mutual_connections', '[]'::jsonb
        );
    END IF;

    -- Caller display name for notification
    SELECT display_name INTO v_my_name FROM public.profiles WHERE id = v_uid;

    -- 4. Record choices
    IF p_choices IS NOT NULL AND jsonb_array_length(p_choices) > 0 THEN
        FOR v_choice_elem IN SELECT * FROM jsonb_array_elements(p_choices)
        LOOP
            v_chosen_id := (v_choice_elem->>'chosen_id')::UUID;
            v_choice_type := TRIM(LOWER(COALESCE(v_choice_elem->>'choice_type', 'no_connection')));

            -- Validate chosen_id
            IF v_chosen_id IS NULL OR v_chosen_id = v_uid THEN
                CONTINUE; -- Ignore invalid or self selection
            END IF;

            -- Validate chosen person was also an attended member of this experience
            IF NOT EXISTS (
                SELECT 1 FROM public.experience_members
                WHERE experience_id = p_experience_id
                  AND user_id = v_chosen_id
                  AND status = 'attended'
            ) THEN
                CONTINUE;
            END IF;

            -- Validate allowed choice type
            IF v_choice_type NOT IN ('friendship', 'activity_partner', 'explore_dating', 'no_connection') THEN
                v_choice_type := 'no_connection';
            END IF;

            -- Insert or replace choice
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

    -- 5. Record final submission
    INSERT INTO public.post_experience_submissions (
        experience_id, user_id, submitted_at
    )
    VALUES (
        p_experience_id, v_uid, v_now
    )
    ON CONFLICT (experience_id, user_id) DO NOTHING;

    -- 6. Evaluate exact mutual matching against partner submissions
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

        -- Check exact compatibility
        IF v_partner_choice IS NOT NULL AND v_partner_choice = v_choice_type THEN

            -- Check block status in either direction
            IF EXISTS (
                SELECT 1 FROM public.blocks
                WHERE (blocker_id = v_uid AND blocked_id = v_chosen_id)
                   OR (blocker_id = v_chosen_id AND blocked_id = v_uid)
            ) THEN
                CONTINUE;
            END IF;

            -- Check suspension status
            IF EXISTS (
                SELECT 1 FROM public.profiles
                WHERE id IN (v_uid, v_chosen_id) AND is_suspended = TRUE
            ) THEN
                CONTINUE;
            END IF;

            -- Canonical user order (user_a < user_b)
            v_user_a := LEAST(v_uid, v_chosen_id);
            v_user_b := GREATEST(v_uid, v_chosen_id);

            -- Check if connection already exists
            SELECT id INTO v_conn_id
              FROM public.connections
             WHERE user_a_id = v_user_a AND user_b_id = v_user_b;

            IF v_conn_id IS NULL THEN
                -- Insert canonical connection
                INSERT INTO public.connections (
                    user_a_id, user_b_id, connection_type, experience_id, created_at
                )
                VALUES (
                    v_user_a, v_user_b, v_choice_type, p_experience_id, v_now
                )
                RETURNING id INTO v_conn_id;

                -- Insert conversation
                INSERT INTO public.conversations (connection_id, created_at, updated_at)
                VALUES (v_conn_id, v_now, v_now)
                ON CONFLICT (connection_id) DO UPDATE SET updated_at = v_now
                RETURNING id INTO v_conv_id;

                -- Insert conversation members for both participants
                INSERT INTO public.conversation_members (conversation_id, user_id, joined_at)
                VALUES (v_conv_id, v_user_a, v_now)
                ON CONFLICT (conversation_id, user_id) DO NOTHING;

                INSERT INTO public.conversation_members (conversation_id, user_id, joined_at)
                VALUES (v_conv_id, v_user_b, v_now)
                ON CONFLICT (conversation_id, user_id) DO NOTHING;

                -- Fetch partner profile details
                SELECT display_name, avatar_url
                  INTO v_partner_name, v_partner_avatar
                  FROM public.profiles
                 WHERE id = v_chosen_id;

                v_type_label := CASE v_choice_type
                    WHEN 'friendship' THEN 'Friendship'
                    WHEN 'activity_partner' THEN 'Activity Partner'
                    WHEN 'explore_dating' THEN 'Explore Dating'
                    ELSE 'Connection'
                END;

                -- Insert in-app notification for caller
                INSERT INTO public.app_notifications (
                    user_id, type, title, message, connection_id, experience_id, created_at
                )
                VALUES (
                    v_uid,
                    'mutual_connection',
                    'New Mutual Connection!',
                    'You and ' || COALESCE(v_partner_name, 'a participant') || ' both chose ' || v_type_label || ' after ' || COALESCE(v_exp_title, 'your experience') || '!',
                    v_conn_id,
                    p_experience_id,
                    v_now
                );

                -- Insert in-app notification for partner
                INSERT INTO public.app_notifications (
                    user_id, type, title, message, connection_id, experience_id, created_at
                )
                VALUES (
                    v_chosen_id,
                    'mutual_connection',
                    'New Mutual Connection!',
                    'You and ' || COALESCE(v_my_name, 'a participant') || ' both chose ' || v_type_label || ' after ' || COALESCE(v_exp_title, 'your experience') || '!',
                    v_conn_id,
                    p_experience_id,
                    v_now
                );

                -- Append to return array for immediate in-app celebration dialog
                v_new_connections := v_new_connections || jsonb_build_object(
                    'connection_id', v_conn_id,
                    'conversation_id', v_conv_id,
                    'partner_id', v_chosen_id,
                    'partner_name', COALESCE(v_partner_name, 'New Connection'),
                    'partner_avatar', COALESCE(v_partner_avatar, ''),
                    'connection_type', v_choice_type,
                    'connection_type_label', v_type_label,
                    'experience_title', COALESCE(v_exp_title, 'Experience')
                );
            END IF;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'submitted', TRUE,
        'already_submitted', FALSE,
        'choices_recorded', v_inserted_choices,
        'mutual_connections', v_new_connections
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_post_experience_choices(UUID, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_post_experience_choices(UUID, JSONB) TO authenticated;

-- ----------------------------------------------------------------------------
-- 9. Supersede & Protect Old Unsafe `process_mutual_connections` (from Migration 003)
--    Prevents bypassing the atomic attendance & exact compatibility matching logic.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_mutual_connections(p_experience_id UUID)
RETURNS TABLE (
    connection_id   UUID,
    user_a          UUID,
    user_b          UUID,
    connection_type TEXT,
    conversation_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RAISE EXCEPTION 'process_mutual_connections is deprecated. Choices must be submitted via submit_post_experience_choices.';
END;
$$;

REVOKE ALL ON FUNCTION public.process_mutual_connections(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.process_mutual_connections(UUID) FROM anon;
REVOKE ALL ON FUNCTION public.process_mutual_connections(UUID) FROM authenticated;

