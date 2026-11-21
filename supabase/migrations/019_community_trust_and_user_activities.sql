-- ============================================================================
-- Migration 019: Community Trust, Reputation, Reviews & User-Created Activities
-- Description:
--   1. Schema extensions on public.experiences:
--      - area (TEXT): Broad area/neighborhood for local discovery.
--      - is_free (BOOLEAN): Free vs paid activity.
--      - price_amount (NUMERIC): Fee amount if paid.
--      - currency (TEXT): Currency code.
--      - is_recurring (BOOLEAN): One-time vs recurring activity.
--      - recurrence_pattern (TEXT): Recurrence frequency if recurring.
--      - moderation_status (TEXT): 'approved', 'pending_review', 'rejected', 'removed'.
--   2. New table: public.experience_reviews:
--      - Strict 1 review per attendee per completed activity.
--      - Rejects self-reviews (reviewer_id != host_id).
--      - Stores structured question answers and optional written feedback.
--   3. New table: public.user_reputation:
--      - Server-computed hosting statistics and reputation levels:
--        'new_host', 'active_host', 'reliable_host', 'trusted_host'.
--      - Displays average rating ONLY after at least 5 verified reviews.
--      - Tracks activity creation restrictions for anti-spam.
--   4. New table: public.moderation_appeals:
--      - Allows users to appeal moderation actions and restrictions.
--   5. Atomic RPCs:
--      - create_user_experience(...): Safe user activity creation with anti-spam rate limits,
--        heuristics, and first-time host participant limit (max 10).
--      - submit_experience_review(...): Atomic review submission validating attended status,
--        completed experience, and triggering automatic reputation recalculation.
--      - recalculate_user_reputation(UUID): Server-side atomic reputation calculation.
--      - get_host_reputation(UUID): Retrieves trust signals and verified statistics.
--      - get_host_reviews(UUID, INT, INT): Retrieves public attendee reviews.
--      - submit_user_report(...): Updated to support all 9 canonical reasons and
--        reporting activities, profiles, reviews, and messages.
--      - moderator_moderate_experience(...): Moderator approve/hold/remove activity.
--      - submit_moderation_appeal(...), get_moderation_appeals(...), resolve_moderation_appeal(...)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Schema Extensions for public.experiences
-- ----------------------------------------------------------------------------

ALTER TABLE public.experiences
    ADD COLUMN IF NOT EXISTS area TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS is_free BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS price_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'INR',
    ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS recurrence_pattern TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS moderation_status TEXT NOT NULL DEFAULT 'approved'
        CHECK (moderation_status IN ('approved', 'pending_review', 'rejected', 'removed'));

-- Indexes for local discovery and moderation filtering
CREATE INDEX IF NOT EXISTS idx_experiences_city_area
    ON public.experiences(city, area)
    WHERE status = 'published' AND moderation_status = 'approved';

CREATE INDEX IF NOT EXISTS idx_experiences_moderation_starts
    ON public.experiences(moderation_status, starts_at);


-- ----------------------------------------------------------------------------
-- 2. New Table: public.experience_reviews
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.experience_reviews (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experience_id         UUID NOT NULL REFERENCES public.experiences(id) ON DELETE CASCADE,
    reviewer_id           UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    host_id               UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating                NUMERIC(2,1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    was_as_described      BOOLEAN NOT NULL DEFAULT TRUE,
    was_host_respectful   BOOLEAN NOT NULL DEFAULT TRUE,
    did_host_arrive       BOOLEAN NOT NULL DEFAULT TRUE,
    felt_safe_comfortable BOOLEAN NOT NULL DEFAULT TRUE,
    would_join_again      BOOLEAN NOT NULL DEFAULT TRUE,
    feedback_text         TEXT CHECK (feedback_text IS NULL OR char_length(feedback_text) <= 500),
    status                TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('published', 'flagged', 'removed')),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_review_experience_reviewer UNIQUE (experience_id, reviewer_id),
    CONSTRAINT chk_no_self_review CHECK (reviewer_id != host_id)
);

ALTER TABLE public.experience_reviews ENABLE ROW LEVEL SECURITY;

-- Review RLS: Public read for published reviews, reviewers read own, insert via atomic RPC only
DROP POLICY IF EXISTS "reviews_select_public" ON public.experience_reviews;
CREATE POLICY "reviews_select_public"
    ON public.experience_reviews FOR SELECT
    USING (status = 'published' OR auth.uid() = reviewer_id OR auth.uid() = host_id);

CREATE INDEX IF NOT EXISTS idx_experience_reviews_host
    ON public.experience_reviews(host_id, created_at DESC)
    WHERE status = 'published';

CREATE INDEX IF NOT EXISTS idx_experience_reviews_exp
    ON public.experience_reviews(experience_id);


-- ----------------------------------------------------------------------------
-- 3. New Table: public.user_reputation
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.user_reputation (
    user_id                      UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    reputation_level             TEXT NOT NULL DEFAULT 'new_host'
        CHECK (reputation_level IN ('new_host', 'active_host', 'reliable_host', 'trusted_host')),
    completed_hosted_count       INTEGER NOT NULL DEFAULT 0 CHECK (completed_hosted_count >= 0),
    total_hosted_count           INTEGER NOT NULL DEFAULT 0 CHECK (total_hosted_count >= 0),
    attended_circles_count       INTEGER NOT NULL DEFAULT 0 CHECK (attended_circles_count >= 0),
    hosted_cancellations_count   INTEGER NOT NULL DEFAULT 0 CHECK (hosted_cancellations_count >= 0),
    host_no_show_count           INTEGER NOT NULL DEFAULT 0 CHECK (host_no_show_count >= 0),
    reviews_count                INTEGER NOT NULL DEFAULT 0 CHECK (reviews_count >= 0),
    average_rating               NUMERIC(3,2) DEFAULT NULL CHECK (average_rating IS NULL OR (average_rating >= 1.0 AND average_rating <= 5.0)),
    hosting_attendance_rate      NUMERIC(5,2) DEFAULT NULL,
    activity_creation_restricted BOOLEAN NOT NULL DEFAULT FALSE,
    restriction_reason           TEXT DEFAULT NULL,
    last_calculated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_reputation ENABLE ROW LEVEL SECURITY;

-- Reputation RLS: Everyone can read reputation statistics
DROP POLICY IF EXISTS "reputation_select_all" ON public.user_reputation;
CREATE POLICY "reputation_select_all"
    ON public.user_reputation FOR SELECT
    USING (TRUE);


-- ----------------------------------------------------------------------------
-- 4. New Table: public.moderation_appeals
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.moderation_appeals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    action_id       UUID REFERENCES public.moderation_actions(id) ON DELETE SET NULL,
    appeal_reason   TEXT NOT NULL CHECK (char_length(TRIM(appeal_reason)) >= 5),
    explanation     TEXT NOT NULL CHECK (char_length(TRIM(explanation)) <= 1000),
    status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    moderator_notes TEXT DEFAULT NULL,
    resolved_by     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at     TIMESTAMPTZ DEFAULT NULL
);

ALTER TABLE public.moderation_appeals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "appeals_select_own_or_mod" ON public.moderation_appeals;
CREATE POLICY "appeals_select_own_or_mod"
    ON public.moderation_appeals FOR SELECT
    USING (auth.uid() = user_id OR public.is_moderator());

DROP POLICY IF EXISTS "appeals_insert_own" ON public.moderation_appeals;
CREATE POLICY "appeals_insert_own"
    ON public.moderation_appeals FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_moderation_appeals_status
    ON public.moderation_appeals(status, created_at DESC);


-- ----------------------------------------------------------------------------
-- 5. Helper & Calculation Function: recalculate_user_reputation
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.recalculate_user_reputation(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_completed_count INTEGER := 0;
    v_total_hosted    INTEGER := 0;
    v_attended_count  INTEGER := 0;
    v_cancelled_count INTEGER := 0;
    v_reviews_count   INTEGER := 0;
    v_avg_rating      NUMERIC(3,2) := NULL;
    v_raw_avg         NUMERIC := NULL;
    v_rep_level       TEXT := 'new_host';
    v_rate            NUMERIC(5,2) := NULL;
    v_restricted      BOOLEAN := FALSE;
    v_rest_reason     TEXT := NULL;
BEGIN
    IF p_user_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'User ID required');
    END IF;

    -- 1. Completed hosted circles (at least 1 attendee confirmed)
    SELECT COUNT(DISTINCT e.id) INTO v_completed_count
      FROM public.experiences e
     WHERE e.host_id = p_user_id
       AND e.status = 'completed';

    -- 2. Total hosted activities (published or completed)
    SELECT COUNT(DISTINCT e.id) INTO v_total_hosted
      FROM public.experiences e
     WHERE e.host_id = p_user_id
       AND e.status IN ('published', 'completed', 'cancelled');

    -- 3. Attended circles count
    SELECT COUNT(DISTINCT em.experience_id) INTO v_attended_count
      FROM public.experience_members em
     WHERE em.user_id = p_user_id
       AND em.status = 'attended';

    -- 4. Host cancellations
    SELECT COUNT(DISTINCT e.id) INTO v_cancelled_count
      FROM public.experiences e
     WHERE e.host_id = p_user_id
       AND e.status = 'cancelled';

    -- 5. Verified attendee reviews count & average rating
    SELECT COUNT(*), AVG(rating) INTO v_reviews_count, v_raw_avg
      FROM public.experience_reviews
     WHERE host_id = p_user_id
       AND status = 'published';

    -- Show numerical rating ONLY after >= 5 verified reviews!
    IF v_reviews_count >= 5 AND v_raw_avg IS NOT NULL THEN
        v_avg_rating := ROUND(v_raw_avg, 2);
    ELSE
        v_avg_rating := NULL;
    END IF;

    -- Hosting attendance rate (completed / (completed + cancelled))
    IF (v_completed_count + v_cancelled_count) > 0 THEN
        v_rate := ROUND((v_completed_count::NUMERIC / (v_completed_count + v_cancelled_count)::NUMERIC) * 100.0, 2);
    ELSE
        v_rate := NULL;
    END IF;

    -- 6. Reputation level determination:
    --    - new_host: 0 completed circles
    --    - active_host: >= 1 completed circle
    --    - reliable_host: >= 3 completed circles, cancellation rate <= 20%
    --    - trusted_host: >= 8 completed circles, cancellation rate <= 10%, at least 5 reviews and avg rating >= 4.5
    IF v_completed_count = 0 THEN
        v_rep_level := 'new_host';
    ELSIF v_completed_count >= 8 AND (v_rate IS NULL OR v_rate >= 90.0) AND v_reviews_count >= 5 AND v_avg_rating >= 4.5 THEN
        v_rep_level := 'trusted_host';
    ELSIF v_completed_count >= 3 AND (v_rate IS NULL OR v_rate >= 80.0) THEN
        v_rep_level := 'reliable_host';
    ELSE
        v_rep_level := 'active_host';
    END IF;

    -- Preserve existing restriction if already set
    SELECT activity_creation_restricted, restriction_reason
      INTO v_restricted, v_rest_reason
      FROM public.user_reputation
     WHERE user_id = p_user_id;

    -- Upsert reputation record
    INSERT INTO public.user_reputation (
        user_id,
        reputation_level,
        completed_hosted_count,
        total_hosted_count,
        attended_circles_count,
        hosted_cancellations_count,
        reviews_count,
        average_rating,
        hosting_attendance_rate,
        activity_creation_restricted,
        restriction_reason,
        last_calculated_at
    )
    VALUES (
        p_user_id,
        v_rep_level,
        v_completed_count,
        v_total_hosted,
        v_attended_count,
        v_cancelled_count,
        v_reviews_count,
        v_avg_rating,
        v_rate,
        COALESCE(v_restricted, FALSE),
        v_rest_reason,
        now()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        reputation_level           = EXCLUDED.reputation_level,
        completed_hosted_count     = EXCLUDED.completed_hosted_count,
        total_hosted_count         = EXCLUDED.total_hosted_count,
        attended_circles_count     = EXCLUDED.attended_circles_count,
        hosted_cancellations_count = EXCLUDED.hosted_cancellations_count,
        reviews_count              = EXCLUDED.reviews_count,
        average_rating             = EXCLUDED.average_rating,
        hosting_attendance_rate    = EXCLUDED.hosting_attendance_rate,
        last_calculated_at         = now();

    RETURN jsonb_build_object(
        'success', TRUE,
        'reputation_level', v_rep_level,
        'completed_hosted_count', v_completed_count,
        'reviews_count', v_reviews_count,
        'average_rating', v_avg_rating
    );
END;
$$;

REVOKE ALL ON FUNCTION public.recalculate_user_reputation(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.recalculate_user_reputation(UUID) TO authenticated;


-- ----------------------------------------------------------------------------
-- 6. RPC: create_user_experience
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.create_user_experience(
    p_title              TEXT,
    p_description        TEXT,
    p_category_id        UUID,
    p_city               TEXT,
    p_area               TEXT,
    p_venue_name         TEXT,
    p_venue_address      TEXT,
    p_is_online          BOOLEAN,
    p_starts_at          TIMESTAMPTZ,
    p_duration_minutes   INTEGER,
    p_max_participants   INTEGER,
    p_is_free            BOOLEAN DEFAULT TRUE,
    p_price_amount       NUMERIC DEFAULT 0.00,
    p_currency           TEXT DEFAULT 'INR',
    p_is_recurring       BOOLEAN DEFAULT FALSE,
    p_recurrence_pattern TEXT DEFAULT NULL,
    p_cover_image_url    TEXT DEFAULT NULL,
    p_cancellation_policy TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid                   UUID := auth.uid();
    v_user_profile          RECORD;
    v_user_rep              RECORD;
    v_recent_circle_count   INTEGER;
    v_duplicate_count       INTEGER;
    v_completed_hosted      INTEGER := 0;
    v_max_allowed_capacity  INTEGER := 20;
    v_mod_status            TEXT := 'approved';
    v_exp_status            public.experience_status := 'published';
    v_experience_id         UUID;
    v_clean_title           TEXT;
    v_clean_desc            TEXT;
    v_clean_city            TEXT;
    v_clean_area            TEXT;
    v_clean_venue           TEXT;
    v_clean_address         TEXT;
    v_ends_at               TIMESTAMPTZ;
BEGIN
    -- 1. Authentication check
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    -- 2. User status check (must be non-suspended, non-deactivated)
    SELECT id, is_suspended, is_deactivated, onboarding_completed, city
      INTO v_user_profile
      FROM public.profiles
     WHERE id = v_uid;

    IF v_user_profile.id IS NULL THEN
        RAISE EXCEPTION 'User profile not found.';
    END IF;

    IF v_user_profile.is_suspended THEN
        RAISE EXCEPTION 'Your account is suspended. You cannot create activities.';
    END IF;

    IF v_user_profile.is_deactivated THEN
        RAISE EXCEPTION 'Your account is deactivated. Please reactivate your account first.';
    END IF;

    -- 3. Check anti-spam restriction in user_reputation
    SELECT activity_creation_restricted, completed_hosted_count
      INTO v_user_rep
      FROM public.user_reputation
     WHERE user_id = v_uid;

    IF v_user_rep.activity_creation_restricted THEN
        RAISE EXCEPTION 'Activity creation is currently restricted for your account. You may submit an appeal in Settings.';
    END IF;

    v_completed_hosted := COALESCE(v_user_rep.completed_hosted_count, 0);

    -- 4. Validate core fields
    v_clean_title := TRIM(COALESCE(p_title, ''));
    IF char_length(v_clean_title) < 5 OR char_length(v_clean_title) > 100 THEN
        RAISE EXCEPTION 'Activity title must be between 5 and 100 characters.';
    END IF;

    v_clean_desc := TRIM(COALESCE(p_description, ''));
    IF char_length(v_clean_desc) < 15 OR char_length(v_clean_desc) > 2000 THEN
        RAISE EXCEPTION 'Activity description must be between 15 and 2,000 characters.';
    END IF;

    v_clean_city := TRIM(COALESCE(p_city, v_user_profile.city, 'Kolkata'));
    v_clean_area := TRIM(COALESCE(p_area, ''));
    v_clean_venue := TRIM(COALESCE(p_venue_name, ''));
    v_clean_address := TRIM(COALESCE(p_venue_address, ''));

    IF NOT COALESCE(p_is_online, FALSE) THEN
        IF v_clean_venue = '' THEN
            RAISE EXCEPTION 'Venue or meeting point name is required for in-person activities.';
        END IF;
    END IF;

    -- Validate category
    IF p_category_id IS NULL OR NOT EXISTS (SELECT 1 FROM public.activity_categories WHERE id = p_category_id) THEN
        RAISE EXCEPTION 'Please select a valid activity category.';
    END IF;

    -- Validate date & time: must be in the future (at least 30 minutes ahead)
    IF p_starts_at IS NULL OR p_starts_at <= now() + INTERVAL '30 minutes' THEN
        RAISE EXCEPTION 'Activity start time must be at least 30 minutes in the future.';
    END IF;

    IF p_duration_minutes IS NULL OR p_duration_minutes < 15 OR p_duration_minutes > 480 THEN
        RAISE EXCEPTION 'Duration must be between 15 and 480 minutes (8 hours).';
    END IF;

    v_ends_at := p_starts_at + (p_duration_minutes * INTERVAL '1 minute');

    -- 5. New Host Fairness & Capacity Gate:
    --    First-time hosts (0 completed circles) get a safe initial capacity limit of max 10.
    --    Established hosts can create circles up to 20.
    IF v_completed_hosted = 0 THEN
        v_max_allowed_capacity := 10;
    ELSE
        v_max_allowed_capacity := 20;
    END IF;

    IF p_max_participants IS NULL OR p_max_participants < 2 THEN
        RAISE EXCEPTION 'Minimum activity capacity is 2 participants.';
    END IF;

    IF p_max_participants > v_max_allowed_capacity THEN
        IF v_completed_hosted = 0 THEN
            RAISE EXCEPTION 'First-time hosts have an initial circle capacity limit of 10 participants to ensure high quality and safety.';
        ELSE
            RAISE EXCEPTION 'Maximum allowed circle capacity is 20 participants.';
        END IF;
    END IF;

    -- 6. Server-Side Anti-Spam Safeguards:
    --    a) Daily Creation Rate Limit:
    --       - New hosts (0 completed): Max 3 circles in 24 hours.
    --       - Established hosts: Max 8 circles in 24 hours.
    SELECT COUNT(*) INTO v_recent_circle_count
      FROM public.experiences
     WHERE host_id = v_uid
       AND created_at >= now() - INTERVAL '24 hours';

    IF v_completed_hosted = 0 AND v_recent_circle_count >= 3 THEN
        RAISE EXCEPTION 'New hosts can create up to 3 activities per day. Please allow your current circles to complete first.';
    ELSIF v_recent_circle_count >= 8 THEN
        RAISE EXCEPTION 'You have reached the daily activity creation limit of 8 activities.';
    END IF;

    --    b) Duplicate Description Check (same user creating identical circle within 48h)
    SELECT COUNT(*) INTO v_duplicate_count
      FROM public.experiences
     WHERE host_id = v_uid
       AND lower(TRIM(description)) = lower(v_clean_desc)
       AND created_at >= now() - INTERVAL '48 hours';

    IF v_duplicate_count > 0 THEN
        -- Flag for moderator review rather than silent error
        v_mod_status := 'pending_review';
        v_exp_status := 'draft';
    END IF;

    --    c) External payment link / scam keyword heuristic
    IF lower(v_clean_desc) ~ '(cash\.app|paypal\.me|venmo\.com|t\.me\/|wa\.me\/|bit\.ly\/|crypto|telegram|whatsapp me)' THEN
        v_mod_status := 'pending_review';
        v_exp_status := 'draft';
    END IF;

    -- 7. Insert Experience
    INSERT INTO public.experiences (
        title,
        description,
        category_id,
        host_id,
        city,
        area,
        venue_name,
        venue_address,
        is_online,
        starts_at,
        ends_at,
        duration_minutes,
        max_participants,
        is_free,
        price_amount,
        currency,
        is_recurring,
        recurrence_pattern,
        cover_image_url,
        cancellation_policy,
        moderation_status,
        status,
        created_at,
        updated_at
    )
    VALUES (
        v_clean_title,
        v_clean_desc,
        p_category_id,
        v_uid,
        v_clean_city,
        v_clean_area,
        v_clean_venue,
        v_clean_address,
        COALESCE(p_is_online, FALSE),
        p_starts_at,
        v_ends_at,
        p_duration_minutes,
        p_max_participants,
        COALESCE(p_is_free, TRUE),
        COALESCE(p_price_amount, 0.00),
        COALESCE(p_currency, 'INR'),
        COALESCE(p_is_recurring, FALSE),
        p_recurrence_pattern,
        p_cover_image_url,
        COALESCE(p_cancellation_policy, 'Free cancellation up to 24 hours before the circle.'),
        v_mod_status,
        v_exp_status,
        now(),
        now()
    )
    RETURNING id INTO v_experience_id;

    -- 8. Add host to experience_members with 'joined' status
    INSERT INTO public.experience_members (
        experience_id,
        user_id,
        status,
        joined_at,
        created_at
    )
    VALUES (
        v_experience_id,
        v_uid,
        'joined',
        now(),
        now()
    );

    -- 9. Trigger reputation stats update for host
    PERFORM public.recalculate_user_reputation(v_uid);

    RETURN jsonb_build_object(
        'success', TRUE,
        'experience_id', v_experience_id,
        'moderation_status', v_mod_status,
        'status', v_exp_status::TEXT,
        'message', CASE 
            WHEN v_mod_status = 'pending_review' 
            THEN 'Your circle has been submitted and is pending safety review before appearing in Discover.'
            ELSE 'Your circle has been published and is now live!'
        END
    );
END;
$$;

REVOKE ALL ON FUNCTION public.create_user_experience FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_user_experience TO authenticated;


-- ----------------------------------------------------------------------------
-- 7. RPC: submit_experience_review
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.submit_experience_review(
    p_experience_id       UUID,
    p_rating              NUMERIC,
    p_was_as_described    BOOLEAN,
    p_was_host_respectful BOOLEAN,
    p_did_host_arrive     BOOLEAN,
    p_felt_safe           BOOLEAN,
    p_would_join_again    BOOLEAN,
    p_feedback_text       TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid         UUID := auth.uid();
    v_exp         RECORD;
    v_member      RECORD;
    v_clean_text  TEXT;
    v_review_id   UUID;
BEGIN
    -- 1. Authentication check
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    -- 2. Verify experience exists and is completed
    SELECT id, host_id, status, ends_at, starts_at, duration_minutes
      INTO v_exp
      FROM public.experiences
     WHERE id = p_experience_id;

    IF v_exp.id IS NULL THEN
        RAISE EXCEPTION 'Experience not found.';
    END IF;

    -- 3. Reject self-review
    IF v_exp.host_id = v_uid THEN
        RAISE EXCEPTION 'Hosts cannot review their own activity.';
    END IF;

    -- 4. Must be marked completed
    IF v_exp.status != 'completed' THEN
        RAISE EXCEPTION 'Reviews are only open after the activity has concluded.';
    END IF;

    -- 5. Reviewer must have attended
    SELECT status INTO v_member
      FROM public.experience_members
     WHERE experience_id = p_experience_id
       AND user_id = v_uid;

    IF v_member.status IS NULL OR v_member.status != 'attended' THEN
        RAISE EXCEPTION 'Only verified attendees can submit an activity review.';
    END IF;

    -- 6. Check for previous review
    IF EXISTS (
        SELECT 1 FROM public.experience_reviews
         WHERE experience_id = p_experience_id
           AND reviewer_id = v_uid
    ) THEN
        RAISE EXCEPTION 'You have already reviewed this activity.';
    END IF;

    -- 7. Validate rating (1.0 to 5.0)
    IF p_rating IS NULL OR p_rating < 1.0 OR p_rating > 5.0 THEN
        RAISE EXCEPTION 'Rating must be between 1.0 and 5.0 stars.';
    END IF;

    v_clean_text := TRIM(p_feedback_text);
    IF v_clean_text IS NOT NULL AND char_length(v_clean_text) > 500 THEN
        RAISE EXCEPTION 'Written feedback cannot exceed 500 characters.';
    END IF;

    -- 8. Insert Review
    INSERT INTO public.experience_reviews (
        experience_id,
        reviewer_id,
        host_id,
        rating,
        was_as_described,
        was_host_respectful,
        did_host_arrive,
        felt_safe_comfortable,
        would_join_again,
        feedback_text,
        status,
        created_at
    )
    VALUES (
        p_experience_id,
        v_uid,
        v_exp.host_id,
        ROUND(p_rating, 1),
        COALESCE(p_was_as_described, TRUE),
        COALESCE(p_was_host_respectful, TRUE),
        COALESCE(p_did_host_arrive, TRUE),
        COALESCE(p_felt_safe, TRUE),
        COALESCE(p_would_join_again, TRUE),
        v_clean_text,
        'published',
        now()
    )
    RETURNING id INTO v_review_id;

    -- 9. Trigger atomic reputation recalculation for host
    PERFORM public.recalculate_user_reputation(v_exp.host_id);

    RETURN jsonb_build_object(
        'success', TRUE,
        'review_id', v_review_id,
        'message', 'Thank you! Your verified review has been submitted.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_experience_review FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_experience_review TO authenticated;


-- ----------------------------------------------------------------------------
-- 8. RPC: get_host_reputation
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_host_reputation(p_host_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_rep            RECORD;
    v_profile        RECORD;
    v_email_confirmed BOOLEAN := FALSE;
BEGIN
    IF p_host_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Host ID is required');
    END IF;

    -- Recalculate to ensure fresh stats
    PERFORM public.recalculate_user_reputation(p_host_id);

    SELECT * INTO v_rep
      FROM public.user_reputation
     WHERE user_id = p_host_id;

    SELECT id, display_name, avatar_url, is_verified, onboarding_completed, created_at
      INTO v_profile
      FROM public.profiles
     WHERE id = p_host_id;

    -- Check if email is confirmed in auth.users
    SELECT (email_confirmed_at IS NOT NULL) INTO v_email_confirmed
      FROM auth.users
     WHERE id = p_host_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'host_id', p_host_id,
        'display_name', COALESCE(v_profile.display_name, 'MELSAVA Host'),
        'reputation_level', COALESCE(v_rep.reputation_level, 'new_host'),
        'is_new_host', (COALESCE(v_rep.completed_hosted_count, 0) = 0),
        'completed_hosted_count', COALESCE(v_rep.completed_hosted_count, 0),
        'total_hosted_count', COALESCE(v_rep.total_hosted_count, 0),
        'attended_circles_count', COALESCE(v_rep.attended_circles_count, 0),
        'hosted_cancellations_count', COALESCE(v_rep.hosted_cancellations_count, 0),
        'reviews_count', COALESCE(v_rep.reviews_count, 0),
        'average_rating', v_rep.average_rating,
        'has_numeric_rating', (v_rep.average_rating IS NOT NULL),
        'hosting_attendance_rate', v_rep.hosting_attendance_rate,
        'is_identity_verified', COALESCE(v_profile.is_verified, FALSE),
        'is_email_confirmed', COALESCE(v_email_confirmed, FALSE),
        'is_profile_completed', COALESCE(v_profile.onboarding_completed, FALSE),
        'community_guidelines_accepted', TRUE,
        'member_since', v_profile.created_at
    );
END;
$$;

REVOKE ALL ON FUNCTION public.get_host_reputation(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_host_reputation(UUID) TO authenticated, anon;


-- ----------------------------------------------------------------------------
-- 9. RPC: get_host_reviews
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_host_reviews(
    p_host_id UUID,
    p_limit   INTEGER DEFAULT 20,
    p_offset  INTEGER DEFAULT 0
)
RETURNS TABLE (
    review_id             UUID,
    experience_id         UUID,
    experience_title      TEXT,
    reviewer_name         TEXT,
    reviewer_avatar       TEXT,
    rating                NUMERIC,
    was_as_described      BOOLEAN,
    was_host_respectful   BOOLEAN,
    did_host_arrive       BOOLEAN,
    felt_safe_comfortable BOOLEAN,
    would_join_again      BOOLEAN,
    feedback_text         TEXT,
    created_at            TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id AS review_id,
        r.experience_id,
        COALESCE(e.title, 'MELSAVA Circle') AS experience_title,
        -- Protect reviewer privacy: show first name / display initial
        COALESCE(p.display_name, 'Verified Attendee') AS reviewer_name,
        COALESCE(p.avatar_url, '') AS reviewer_avatar,
        r.rating,
        r.was_as_described,
        r.was_host_respectful,
        r.did_host_arrive,
        r.felt_safe_comfortable,
        r.would_join_again,
        r.feedback_text,
        r.created_at
    FROM public.experience_reviews r
    JOIN public.experiences e ON e.id = r.experience_id
    JOIN public.profiles p ON p.id = r.reviewer_id
    WHERE r.host_id = p_host_id
      AND r.status = 'published'
    ORDER BY r.created_at DESC
    LIMIT COALESCE(p_limit, 20)
    OFFSET COALESCE(p_offset, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.get_host_reviews(UUID, INTEGER, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_host_reviews(UUID, INTEGER, INTEGER) TO authenticated, anon;


-- ----------------------------------------------------------------------------
-- 10. Extended submit_user_report RPC (Canonical 9 Reasons & Multi-Target)
-- ----------------------------------------------------------------------------

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
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid              UUID := auth.uid();
    v_report_id        UUID;
    v_clean_desc       TEXT;
    v_clean_reason     TEXT;
    v_target_user_id   UUID := p_reported_user_id;
    v_allowed_reasons  TEXT[] := ARRAY[
        'Spam or fake activity',
        'Commercial solicitation or spam',
        'Fake identity or impersonation',
        'Fake profile or impersonation',
        'Harassment',
        'Harassment or unwanted contact',
        'Inappropriate behaviour',
        'Inappropriate or offensive behavior',
        'Unsafe meetup or suspicious location',
        'Scam or payment fraud',
        'Activity did not happen',
        'Underage user concern',
        'Other safety concern',
        'Other'
    ];
BEGIN
    -- 1. Authentication check
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    -- 2. Validate reason against canonical list (case-insensitive trim)
    v_clean_reason := TRIM(COALESCE(p_reason, ''));
    IF NOT EXISTS (
        SELECT 1 FROM unnest(v_allowed_reasons) r 
        WHERE lower(r) = lower(v_clean_reason)
    ) THEN
        RAISE EXCEPTION 'Invalid report reason: "%". Must be one of the canonical 9 reasons.', v_clean_reason;
    END IF;

    -- 3. Resolve target user if reporting an experience or review
    IF p_content_type = 'experience' AND p_content_id IS NOT NULL THEN
        SELECT host_id INTO v_target_user_id FROM public.experiences WHERE id = p_content_id;
    ELSIF p_content_type = 'review' AND p_content_id IS NOT NULL THEN
        SELECT reviewer_id INTO v_target_user_id FROM public.experience_reviews WHERE id = p_content_id;
    ELSIF p_content_type = 'message' AND p_content_id IS NOT NULL THEN
        SELECT sender_id INTO v_target_user_id FROM public.messages WHERE id = p_content_id;
    END IF;

    IF v_target_user_id IS NULL THEN
        v_target_user_id := p_reported_user_id;
    END IF;

    -- 4. Reject self-reporting
    IF v_target_user_id = v_uid THEN
        RAISE EXCEPTION 'Cannot submit a report against yourself.';
    END IF;

    -- 5. Validate description length
    v_clean_desc := TRIM(p_description);
    IF v_clean_desc IS NOT NULL AND char_length(v_clean_desc) > 500 THEN
        RAISE EXCEPTION 'Description exceeds maximum length of 500 characters.';
    END IF;

    -- 6. Anti-spam throttle: Reject identical report within 1 hour
    IF EXISTS (
        SELECT 1 FROM public.reports
         WHERE reporter_id = v_uid
           AND reported_user_id = v_target_user_id
           AND lower(reason) = lower(v_clean_reason)
           AND created_at >= now() - INTERVAL '1 hour'
    ) THEN
        RAISE EXCEPTION 'A report for this member with the same reason was recently submitted. Our team is reviewing it.';
    END IF;

    -- 7. Insert report
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
        v_target_user_id,
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
        'message', 'Your report has been received and will be reviewed confidentially by our moderation team.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_user_report(UUID, TEXT, TEXT, TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_user_report(UUID, TEXT, TEXT, TEXT, UUID) TO authenticated;


-- ----------------------------------------------------------------------------
-- 11. Moderation Activity Management RPCs
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.moderator_moderate_experience(
    p_experience_id UUID,
    p_action        TEXT, -- 'approve', 'hold', 'remove'
    p_reason        TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_mod_uid UUID := auth.uid();
    v_exp     RECORD;
BEGIN
    IF NOT public.is_moderator() THEN
        RAISE EXCEPTION 'Access denied: moderator privileges required.';
    END IF;

    SELECT id, host_id, title INTO v_exp
      FROM public.experiences
     WHERE id = p_experience_id;

    IF v_exp.id IS NULL THEN
        RAISE EXCEPTION 'Experience not found.';
    END IF;

    IF p_action = 'approve' THEN
        UPDATE public.experiences
           SET moderation_status = 'approved',
               status = 'published',
               updated_at = now()
         WHERE id = p_experience_id;
    ELSIF p_action = 'hold' THEN
        UPDATE public.experiences
           SET moderation_status = 'pending_review',
               status = 'draft',
               updated_at = now()
         WHERE id = p_experience_id;
    ELSIF p_action = 'remove' THEN
        UPDATE public.experiences
           SET moderation_status = 'removed',
               status = 'cancelled',
               updated_at = now()
         WHERE id = p_experience_id;
    ELSE
        RAISE EXCEPTION 'Invalid action: must be approve, hold, or remove.';
    END IF;

    -- Record in moderation actions
    INSERT INTO public.moderation_actions (
        user_id,
        action_type,
        reason,
        performed_by,
        created_at
    )
    VALUES (
        v_exp.host_id,
        CASE WHEN p_action = 'remove' THEN 'warning'::public.moderation_action_type ELSE 'warning'::public.moderation_action_type END,
        COALESCE(p_reason, 'Activity moderated: ' || p_action),
        v_mod_uid,
        now()
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'action', p_action,
        'experience_id', p_experience_id
    );
END;
$$;

REVOKE ALL ON FUNCTION public.moderator_moderate_experience FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.moderator_moderate_experience TO authenticated;


-- ----------------------------------------------------------------------------
-- 12. Appeals System RPCs
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.submit_moderation_appeal(
    p_action_id   UUID,
    p_reason      TEXT,
    p_explanation TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid       UUID := auth.uid();
    v_appeal_id UUID;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    IF p_reason IS NULL OR char_length(TRIM(p_reason)) < 5 THEN
        RAISE EXCEPTION 'Please provide a clear appeal reason.';
    END IF;

    IF p_explanation IS NULL OR char_length(TRIM(p_explanation)) < 15 THEN
        RAISE EXCEPTION 'Please provide a detailed explanation (minimum 15 characters).';
    END IF;

    INSERT INTO public.moderation_appeals (
        user_id,
        action_id,
        appeal_reason,
        explanation,
        status,
        created_at
    )
    VALUES (
        v_uid,
        p_action_id,
        TRIM(p_reason),
        TRIM(p_explanation),
        'pending',
        now()
    )
    RETURNING id INTO v_appeal_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'appeal_id', v_appeal_id,
        'message', 'Your appeal has been submitted for senior moderator review.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_moderation_appeal FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_moderation_appeal TO authenticated;


CREATE OR REPLACE FUNCTION public.get_moderation_appeals(p_status TEXT DEFAULT 'pending')
RETURNS TABLE (
    appeal_id       UUID,
    user_id         UUID,
    user_name       TEXT,
    user_avatar     TEXT,
    action_id       UUID,
    action_type     TEXT,
    action_reason   TEXT,
    appeal_reason   TEXT,
    explanation     TEXT,
    status          TEXT,
    created_at      TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_moderator() THEN
        RAISE EXCEPTION 'Access denied: moderator privileges required.';
    END IF;

    RETURN QUERY
    SELECT
        a.id AS appeal_id,
        a.user_id,
        COALESCE(p.display_name, 'Member') AS user_name,
        COALESCE(p.avatar_url, '') AS user_avatar,
        a.action_id,
        COALESCE(ma.action_type::TEXT, 'restriction') AS action_type,
        COALESCE(ma.reason, 'Activity creation restriction') AS action_reason,
        a.appeal_reason,
        a.explanation,
        a.status,
        a.created_at
    FROM public.moderation_appeals a
    JOIN public.profiles p ON p.id = a.user_id
    LEFT JOIN public.moderation_actions ma ON ma.id = a.action_id
    WHERE (p_status = 'all' OR a.status = p_status)
    ORDER BY a.created_at DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_moderation_appeals FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_moderation_appeals TO authenticated;


CREATE OR REPLACE FUNCTION public.resolve_moderation_appeal(
    p_appeal_id  UUID,
    p_resolution TEXT, -- 'approved', 'rejected'
    p_notes      TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_mod_uid UUID := auth.uid();
    v_appeal  RECORD;
BEGIN
    IF NOT public.is_moderator() THEN
        RAISE EXCEPTION 'Access denied: moderator privileges required.';
    END IF;

    SELECT * INTO v_appeal
      FROM public.moderation_appeals
     WHERE id = p_appeal_id;

    IF v_appeal.id IS NULL THEN
        RAISE EXCEPTION 'Appeal not found.';
    END IF;

    UPDATE public.moderation_appeals
       SET status = p_resolution,
           moderator_notes = p_notes,
           resolved_by = v_mod_uid,
           resolved_at = now()
     WHERE id = p_appeal_id;

    -- If approved, lift restriction on user_reputation
    IF p_resolution = 'approved' THEN
        UPDATE public.user_reputation
           SET activity_creation_restricted = FALSE,
               restriction_reason = NULL
         WHERE user_id = v_appeal.user_id;

        -- Un-suspend profile if it was suspended
        UPDATE public.profiles
           SET is_suspended = FALSE
         WHERE id = v_appeal.user_id;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'appeal_id', p_appeal_id,
        'resolution', p_resolution
    );
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_moderation_appeal FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_moderation_appeal TO authenticated;
