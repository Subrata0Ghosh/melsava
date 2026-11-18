-- ============================================================================
-- MELSAVA — Phase 2: Atomic Onboarding Completion, Experience Joining,
--                    FIFO Waitlist Promotion, Public Count Helper & Tight RLS
-- Migration: 006_phase2_experiences_rls_and_rpc.sql
-- Description:
--   1. Adds atomic `complete_profile_onboarding()` RPC so onboarding_completed
--      is only set TRUE after profiles, profile_private, interests, and
--      intentions all persist in one transaction.
--   2. Tightens `experience_members` RLS so clients cannot bypass capacity
--      checks, duplicate constraints, or self-assign `attended` status.
--   3. Adds `get_experience_participant_counts()` RPC to expose only aggregate
--      counts (zero PII) for published experiences.
--   4. Adds atomic `join_experience()` RPC with row-level locking (`FOR UPDATE`),
--      eligibility verification, duplicate prevention, and automatic waitlisting.
--   5. Adds atomic `cancel_experience_membership()` RPC with FIFO waitlist
--      promotion (`ORDER BY joined_at ASC, created_at ASC, id ASC`).
--   6. Adds targeted composite indexes for discovery and FIFO waitlist queries.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Helpful composite indexes for Phase 2 queries
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_experiences_published_starts_at
    ON public.experiences (status, starts_at)
    WHERE status = 'published';

CREATE INDEX IF NOT EXISTS idx_experience_members_exp_status_fifo
    ON public.experience_members (experience_id, status, joined_at ASC, created_at ASC, id ASC);

-- ----------------------------------------------------------------------------
-- 2. Atomic Onboarding Completion RPC (Fixes Phase 1 Data-Integrity Issue)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_profile_onboarding(
    p_display_name TEXT,
    p_avatar_url TEXT,
    p_city TEXT,
    p_bio TEXT,
    p_interest_names TEXT[],
    p_activity_categories TEXT[],
    p_primary_intention TEXT,
    p_intention_names TEXT[],
    p_availability JSONB,
    p_discovery_preferences JSONB,
    p_guidelines_accepted BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid               UUID := auth.uid();
    v_email             TEXT;
    v_age_verified      BOOLEAN := FALSE;
    v_trimmed_name      TEXT := TRIM(COALESCE(p_display_name, ''));
    v_trimmed_city      TEXT := TRIM(COALESCE(p_city, ''));
    v_trimmed_bio       TEXT := TRIM(COALESCE(p_bio, ''));
    v_interest_count    INTEGER := 0;
    v_intention_count   INTEGER := 0;
    v_now               TIMESTAMPTZ := now();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required to complete onboarding.';
    END IF;

    IF char_length(v_trimmed_name) < 2 OR char_length(v_trimmed_name) > 50 THEN
        RAISE EXCEPTION 'Display name must be between 2 and 50 characters.';
    END IF;

    IF char_length(v_trimmed_city) < 2 THEN
        RAISE EXCEPTION 'City or broad area is required.';
    END IF;

    IF char_length(v_trimmed_bio) > 500 THEN
        RAISE EXCEPTION 'Bio must be 500 characters or fewer.';
    END IF;

    IF COALESCE(p_guidelines_accepted, FALSE) IS NOT TRUE THEN
        RAISE EXCEPTION 'Community guidelines must be accepted to complete onboarding.';
    END IF;

    -- Confirm user completed 18+ adult eligibility first
    SELECT age_verified, email
      INTO v_age_verified, v_email
      FROM public.profile_private
     WHERE user_id = v_uid;

    IF COALESCE(v_age_verified, FALSE) IS NOT TRUE THEN
        RAISE EXCEPTION 'Adult eligibility (18+) must be verified before completing onboarding.';
    END IF;

    IF v_email IS NULL THEN
        SELECT email INTO v_email FROM auth.users WHERE id = v_uid;
    END IF;

    -- 1. Save base profile fields (keep onboarding_completed = FALSE until all relations succeed)
    INSERT INTO public.profiles (
        id,
        display_name,
        avatar_url,
        bio,
        city,
        onboarding_completed,
        updated_at
    )
    VALUES (
        v_uid,
        v_trimmed_name,
        NULLIF(TRIM(COALESCE(p_avatar_url, '')), ''),
        v_trimmed_bio,
        v_trimmed_city,
        FALSE,
        v_now
    )
    ON CONFLICT (id) DO UPDATE SET
        display_name = EXCLUDED.display_name,
        avatar_url   = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
        bio          = EXCLUDED.bio,
        city         = EXCLUDED.city,
        updated_at   = v_now;

    -- 2. Save compliance timestamps & preferences in profile_private
    UPDATE public.profile_private
       SET email                         = COALESCE(email, v_email),
           terms_accepted_at             = COALESCE(terms_accepted_at, v_now),
           guidelines_accepted_at        = v_now,
           preferred_activity_categories = COALESCE(p_activity_categories, '{}'),
           availability_preferences      = COALESCE(p_availability, '[]'::jsonb),
           discovery_preferences         = COALESCE(p_discovery_preferences, '{}'::jsonb)
     WHERE user_id = v_uid;

    -- 3. Replace profile_interests atomically (no duplicates on retry)
    IF p_interest_names IS NULL OR array_length(p_interest_names, 1) IS NULL THEN
        RAISE EXCEPTION 'Please select at least one interest.';
    END IF;

    DELETE FROM public.profile_interests WHERE profile_id = v_uid;

    INSERT INTO public.profile_interests (profile_id, interest_id)
    SELECT v_uid, i.id
      FROM public.interests i
     WHERE i.name = ANY(p_interest_names)
    ON CONFLICT (profile_id, interest_id) DO NOTHING;

    GET DIAGNOSTICS v_interest_count = ROW_COUNT;
    IF v_interest_count < 1 THEN
        RAISE EXCEPTION 'Could not save selected interests. Please ensure reference interests are seeded and retry.';
    END IF;

    -- 4. Replace profile_intentions atomically (no duplicates on retry)
    IF p_intention_names IS NULL OR array_length(p_intention_names, 1) IS NULL THEN
        RAISE EXCEPTION 'Please select at least one connection intention.';
    END IF;

    DELETE FROM public.profile_intentions WHERE profile_id = v_uid;

    INSERT INTO public.profile_intentions (profile_id, intention_id, is_primary)
    SELECT v_uid, it.id, (it.name = p_primary_intention)
      FROM public.intentions it
     WHERE it.name = ANY(p_intention_names)
        OR it.name = p_primary_intention
    ON CONFLICT (profile_id, intention_id) DO UPDATE
        SET is_primary = EXCLUDED.is_primary;

    GET DIAGNOSTICS v_intention_count = ROW_COUNT;
    IF v_intention_count < 1 THEN
        RAISE EXCEPTION 'Could not save selected connection intentions. Please ensure reference intentions are seeded and retry.';
    END IF;

    -- 5. Mark onboarding complete ONLY after every required write succeeded
    UPDATE public.profiles
       SET onboarding_completed = TRUE,
           updated_at = v_now
     WHERE id = v_uid;

    RETURN jsonb_build_object(
        'onboarding_completed', TRUE,
        'interests_saved', v_interest_count,
        'intentions_saved', v_intention_count
    );
END;
$$;

REVOKE ALL ON FUNCTION public.complete_profile_onboarding(
    TEXT, TEXT, TEXT, TEXT, TEXT[], TEXT[], TEXT, TEXT[], JSONB, JSONB, BOOLEAN
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_profile_onboarding(
    TEXT, TEXT, TEXT, TEXT, TEXT[], TEXT[], TEXT, TEXT[], JSONB, JSONB, BOOLEAN
) TO authenticated;

-- ----------------------------------------------------------------------------
-- 3. Tighten `experience_members` RLS Policies & Prevent Infinite Recursion
--    All mutations flow through atomic RPCs (join_experience, cancel_experience_membership).
--    Uses SECURITY DEFINER helpers to avoid cyclic RLS evaluation between
--    experiences and experience_members.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "experience_members_insert_own" ON public.experience_members;
DROP POLICY IF EXISTS "experience_members_update_own" ON public.experience_members;

-- Helper function: check if caller is host (SECURITY DEFINER breaks RLS recursion)
CREATE OR REPLACE FUNCTION public.is_experience_host(p_experience_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.experiences
        WHERE id = p_experience_id AND host_id = auth.uid()
    );
$$;

REVOKE ALL ON FUNCTION public.is_experience_host(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_experience_host(UUID) TO authenticated;

-- Helper function: check if caller is member (SECURITY DEFINER breaks RLS recursion)
CREATE OR REPLACE FUNCTION public.is_experience_member(p_experience_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.experience_members
        WHERE experience_id = p_experience_id
          AND user_id = auth.uid()
          AND status IN ('joined', 'attended')
    );
$$;

REVOKE ALL ON FUNCTION public.is_experience_member(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_experience_member(UUID) TO authenticated;

-- Replace recursive select policy on experience_members
DROP POLICY IF EXISTS "experience_members_select" ON public.experience_members;

CREATE POLICY "experience_members_select"
    ON public.experience_members FOR SELECT
    TO authenticated
    USING (
        user_id = auth.uid()
        OR public.is_experience_host(experience_id)
    );

-- Allow hosts (not regular attendees) to mark members as attended when needed.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'experience_members'
          AND policyname = 'experience_members_host_mark_attended'
    ) THEN
        CREATE POLICY "experience_members_host_mark_attended"
            ON public.experience_members FOR UPDATE
            TO authenticated
            USING (public.is_experience_host(experience_id))
            WITH CHECK (public.is_experience_host(experience_id));
    END IF;
END $$;

-- Also ensure users can read completed experiences they participated in (for My Circles / Past)
DROP POLICY IF EXISTS "experiences_select_member_history" ON public.experiences;

CREATE POLICY "experiences_select_member_history"
    ON public.experiences FOR SELECT
    TO authenticated
    USING (public.is_experience_member(id));

-- ----------------------------------------------------------------------------
-- 4. Public Aggregate Participant Counts RPC (Zero PII Exposed)
--    Allows discovery & detail screens to show accurate live capacity counts
--    for published experiences without exposing member rows to non-members.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_experience_participant_counts(
    p_experience_ids UUID[]
)
RETURNS TABLE (
    experience_id     UUID,
    joined_count      INTEGER,
    waitlisted_count  INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        e.id AS experience_id,
        COALESCE(
            COUNT(em.id) FILTER (WHERE em.status IN ('joined', 'attended')),
            0
        )::INTEGER AS joined_count,
        COALESCE(
            COUNT(em.id) FILTER (WHERE em.status = 'waitlisted'),
            0
        )::INTEGER AS waitlisted_count
    FROM public.experiences e
    LEFT JOIN public.experience_members em
        ON em.experience_id = e.id
    WHERE e.id = ANY(p_experience_ids)
      AND (
          e.status = 'published'
          OR e.host_id = auth.uid()
          OR EXISTS (
              SELECT 1 FROM public.experience_members em_self
              WHERE em_self.experience_id = e.id
                AND em_self.user_id = auth.uid()
          )
      )
    GROUP BY e.id;
$$;

REVOKE ALL ON FUNCTION public.get_experience_participant_counts(UUID[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_experience_participant_counts(UUID[]) TO authenticated;

-- ----------------------------------------------------------------------------
-- 5. Atomic Join / Waitlist RPC (`join_experience`)
--    - Requires authenticated, non-suspended, 18+ verified, onboarded user
--    - Locks target experience row (`FOR UPDATE`) to prevent overbooking races
--    - Enforces published & upcoming status
--    - Prevents duplicate membership
--    - Joins if spot available, or adds FIFO waitlisted if full
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.join_experience(
    p_experience_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid                   UUID := auth.uid();
    v_onboarding_completed  BOOLEAN := FALSE;
    v_is_suspended          BOOLEAN := FALSE;
    v_age_verified          BOOLEAN := FALSE;
    v_exp_status            public.experience_status;
    v_starts_at             TIMESTAMPTZ;
    v_max_participants      INTEGER;
    v_existing_status       public.member_status;
    v_current_joined        INTEGER := 0;
    v_new_status            public.member_status;
    v_waitlist_count        INTEGER := 0;
    v_now                   TIMESTAMPTZ := now();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Please sign in to join an experience.';
    END IF;

    -- Validate caller eligibility (profile complete, not suspended, 18+ verified)
    SELECT p.onboarding_completed, p.is_suspended, COALESCE(pp.age_verified, FALSE)
      INTO v_onboarding_completed, v_is_suspended, v_age_verified
      FROM public.profiles p
      LEFT JOIN public.profile_private pp ON pp.user_id = p.id
     WHERE p.id = v_uid;

    IF NOT FOUND OR v_onboarding_completed IS NOT TRUE THEN
        RAISE EXCEPTION 'Please complete your profile onboarding before joining experiences.';
    END IF;

    IF v_is_suspended IS TRUE THEN
        RAISE EXCEPTION 'Your account is currently unable to join experiences.';
    END IF;

    IF v_age_verified IS NOT TRUE THEN
        RAISE EXCEPTION 'Adult eligibility (18+) verification is required to join experiences.';
    END IF;

    -- Serialize concurrent join/cancel operations on this experience
    SELECT status, starts_at, max_participants
      INTO v_exp_status, v_starts_at, v_max_participants
      FROM public.experiences
     WHERE id = p_experience_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'This experience could not be found.';
    END IF;

    IF v_exp_status != 'published' THEN
        RAISE EXCEPTION 'This experience is not currently open for joining.';
    END IF;

    IF v_starts_at IS NOT NULL AND v_starts_at <= v_now THEN
        RAISE EXCEPTION 'This experience has already started or passed.';
    END IF;

    -- Check existing membership (prevent duplicate joins)
    SELECT status
      INTO v_existing_status
      FROM public.experience_members
     WHERE experience_id = p_experience_id
       AND user_id = v_uid;

    IF v_existing_status IN ('joined', 'waitlisted', 'attended') THEN
        SELECT
            COALESCE(COUNT(*) FILTER (WHERE status IN ('joined', 'attended')), 0)::INTEGER,
            COALESCE(COUNT(*) FILTER (WHERE status = 'waitlisted'), 0)::INTEGER
          INTO v_current_joined, v_waitlist_count
          FROM public.experience_members
         WHERE experience_id = p_experience_id;

        RETURN jsonb_build_object(
            'status', v_existing_status::TEXT,
            'already_member', TRUE,
            'current_participants', v_current_joined,
            'max_participants', v_max_participants,
            'waitlist_count', v_waitlist_count
        );
    END IF;

    -- Count active joined/attended participants under the experience row lock
    SELECT COALESCE(COUNT(*), 0)::INTEGER
      INTO v_current_joined
      FROM public.experience_members
     WHERE experience_id = p_experience_id
       AND status IN ('joined', 'attended');

    IF v_max_participants IS NULL OR v_current_joined < v_max_participants THEN
        v_new_status := 'joined';
    ELSE
        v_new_status := 'waitlisted';
    END IF;

    -- Insert new membership or reactivate a previously cancelled row with fresh FIFO timestamp
    INSERT INTO public.experience_members (
        experience_id,
        user_id,
        status,
        joined_at,
        cancelled_at,
        created_at
    )
    VALUES (
        p_experience_id,
        v_uid,
        v_new_status,
        v_now,
        NULL,
        v_now
    )
    ON CONFLICT (experience_id, user_id) DO UPDATE SET
        status       = EXCLUDED.status,
        joined_at    = v_now,
        cancelled_at = NULL;

    -- Recalculate accurate post-operation counts
    SELECT
        COALESCE(COUNT(*) FILTER (WHERE status IN ('joined', 'attended')), 0)::INTEGER,
        COALESCE(COUNT(*) FILTER (WHERE status = 'waitlisted'), 0)::INTEGER
      INTO v_current_joined, v_waitlist_count
      FROM public.experience_members
     WHERE experience_id = p_experience_id;

    RETURN jsonb_build_object(
        'status', v_new_status::TEXT,
        'already_member', FALSE,
        'current_participants', v_current_joined,
        'max_participants', v_max_participants,
        'waitlist_count', v_waitlist_count
    );
END;
$$;

REVOKE ALL ON FUNCTION public.join_experience(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_experience(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 6. Atomic Cancel & FIFO Waitlist Promotion RPC (`cancel_experience_membership`)
--    - Locks target experience row (`FOR UPDATE`) to prevent overbooking races
--    - Cancels caller's own `joined` or `waitlisted` membership
--    - If caller was `joined` and experience is still open/upcoming, promotes
--      the earliest waitlisted member (FIFO by joined_at, created_at, id)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cancel_experience_membership(
    p_experience_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid               UUID := auth.uid();
    v_exp_status        public.experience_status;
    v_starts_at         TIMESTAMPTZ;
    v_max_participants  INTEGER;
    v_prev_status       public.member_status;
    v_current_joined    INTEGER := 0;
    v_waitlist_count    INTEGER := 0;
    v_promoted_member   UUID;
    v_promoted_user_id  UUID;
    v_now               TIMESTAMPTZ := now();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Please sign in to manage your RSVP.';
    END IF;

    -- Lock experience row to serialize with concurrent joins/cancellations
    SELECT status, starts_at, max_participants
      INTO v_exp_status, v_starts_at, v_max_participants
      FROM public.experiences
     WHERE id = p_experience_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'This experience could not be found.';
    END IF;

    SELECT status
      INTO v_prev_status
      FROM public.experience_members
     WHERE experience_id = p_experience_id
       AND user_id = v_uid
       FOR UPDATE;

    IF NOT FOUND OR v_prev_status NOT IN ('joined', 'waitlisted') THEN
        RAISE EXCEPTION 'You do not have an active reservation for this experience.';
    END IF;

    -- Cancel caller's membership
    UPDATE public.experience_members
       SET status       = 'cancelled',
           cancelled_at = v_now
     WHERE experience_id = p_experience_id
       AND user_id = v_uid;

    -- FIFO waitlist promotion when a joined member frees a spot on an upcoming published experience
    IF v_prev_status = 'joined'
       AND v_exp_status = 'published'
       AND (v_starts_at IS NULL OR v_starts_at > v_now) THEN

        SELECT COALESCE(COUNT(*), 0)::INTEGER
          INTO v_current_joined
          FROM public.experience_members
         WHERE experience_id = p_experience_id
           AND status IN ('joined', 'attended');

        IF v_max_participants IS NULL OR v_current_joined < v_max_participants THEN
            SELECT em.id, em.user_id
              INTO v_promoted_member, v_promoted_user_id
              FROM public.experience_members em
              JOIN public.profiles p ON p.id = em.user_id
             WHERE em.experience_id = p_experience_id
               AND em.status = 'waitlisted'
               AND p.is_suspended = FALSE
             ORDER BY em.joined_at ASC, em.created_at ASC, em.id ASC
             LIMIT 1
               FOR UPDATE OF em SKIP LOCKED;

            IF v_promoted_member IS NOT NULL THEN
                UPDATE public.experience_members
                   SET status       = 'joined',
                       cancelled_at = NULL
                 WHERE id = v_promoted_member;
            END IF;
        END IF;
    END IF;

    -- Recompute latest counts
    SELECT
        COALESCE(COUNT(*) FILTER (WHERE status IN ('joined', 'attended')), 0)::INTEGER,
        COALESCE(COUNT(*) FILTER (WHERE status = 'waitlisted'), 0)::INTEGER
      INTO v_current_joined, v_waitlist_count
      FROM public.experience_members
     WHERE experience_id = p_experience_id;

    RETURN jsonb_build_object(
        'status', 'cancelled',
        'previous_status', v_prev_status::TEXT,
        'promoted_user_id', v_promoted_user_id,
        'current_participants', v_current_joined,
        'max_participants', v_max_participants,
        'waitlist_count', v_waitlist_count
    );
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_experience_membership(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_experience_membership(UUID) TO authenticated;
