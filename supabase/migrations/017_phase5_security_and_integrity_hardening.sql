-- ============================================================================
-- Migration 017: Phase 5 Security, Data Integrity & Production Hardening
-- Description:
--   1. Schema: Adds missing columns to profile_private (preferred_activity_categories,
--      availability_preferences, discovery_preferences, privacy_settings).
--   2. Permanent Account Deletion: Safely revokes and removes legacy delete_user_account_permanent
--      RPC (Edge Function via Supabase Admin API is the only permanent deletion mechanism).
--   3. Profile Data Integrity: Replaces update_user_profile() with strict validation:
--      - Validates all interest names against public.interests prior to deleting old selections.
--      - Validates primary and secondary intention names against public.intentions.
--      - Rejects duplicate interests and intentions.
--      - Enforces exactly one primary intention.
--      - Validates discovery preference age and distance ranges.
--      - Safely upserts profile_private and prevents client modifications to protected columns.
--   4. Reporting System Hardening: Replaces submit_user_report() with strict allowlist
--      validation for the 9 canonical reasons, 500-char description limit, and anti-spam check.
--   5. Block Management: Ensures server-enforced block_user and unblock_user RPCs.
--   6. Privacy Settings Persistence: Adds get_privacy_settings() and update_privacy_settings() RPCs.
-- ============================================================================

-- 1. Schema Additions for profile_private
ALTER TABLE public.profile_private
    ADD COLUMN IF NOT EXISTS preferred_activity_categories TEXT[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS availability_preferences JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS discovery_preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS privacy_settings JSONB NOT NULL DEFAULT '{"public_radar": true, "ghost_mode": false, "show_city": true}'::jsonb;

-- 2. Revoke and Drop Legacy Permanent Deletion SQL RPC
REVOKE ALL ON FUNCTION public.delete_user_account_permanent(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_user_account_permanent(TEXT) FROM anon, authenticated;
DROP FUNCTION IF EXISTS public.delete_user_account_permanent(TEXT);


-- 3. Hardened Atomic update_user_profile RPC
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
    v_uid                   UUID := auth.uid();
    v_interest_name         TEXT;
    v_interest_id           UUID;
    v_interest_ids          UUID[] := '{}';
    v_seen_interests        TEXT[] := '{}';
    v_primary_intent_id     UUID;
    v_secondary_name        TEXT;
    v_secondary_id          UUID;
    v_secondary_ids         UUID[] := '{}';
    v_seen_intentions       TEXT[] := '{}';
    v_min_age               INTEGER;
    v_max_age               INTEGER;
    v_max_dist              INTEGER;
BEGIN
    -- 1. Authentication check
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    -- 2. Validate display name
    IF p_display_name IS NULL OR char_length(TRIM(p_display_name)) < 2 THEN
        RAISE EXCEPTION 'Display name must be at least 2 characters.';
    END IF;

    IF char_length(TRIM(p_display_name)) > 50 THEN
        RAISE EXCEPTION 'Display name cannot exceed 50 characters.';
    END IF;

    -- 3. Validate bio
    IF p_bio IS NOT NULL AND char_length(TRIM(p_bio)) > 500 THEN
        RAISE EXCEPTION 'Bio cannot exceed 500 characters.';
    END IF;

    -- 4. Validate discovery preferences (if provided)
    IF p_discovery_preferences IS NOT NULL AND p_discovery_preferences != '{}'::jsonb THEN
        IF p_discovery_preferences ? 'min_age' AND p_discovery_preferences->>'min_age' IS NOT NULL THEN
            v_min_age := (p_discovery_preferences->>'min_age')::INTEGER;
            IF v_min_age < 18 OR v_min_age > 99 THEN
                RAISE EXCEPTION 'Invalid discovery preference: min_age must be between 18 and 99.';
            END IF;
        END IF;

        IF p_discovery_preferences ? 'max_age' AND p_discovery_preferences->>'max_age' IS NOT NULL THEN
            v_max_age := (p_discovery_preferences->>'max_age')::INTEGER;
            IF v_max_age < 18 OR v_max_age > 100 THEN
                RAISE EXCEPTION 'Invalid discovery preference: max_age must be between 18 and 100.';
            END IF;
            IF v_min_age IS NOT NULL AND v_max_age < v_min_age THEN
                RAISE EXCEPTION 'Invalid discovery preference: max_age cannot be less than min_age.';
            END IF;
        END IF;

        IF p_discovery_preferences ? 'max_distance_km' AND p_discovery_preferences->>'max_distance_km' IS NOT NULL THEN
            v_max_dist := (p_discovery_preferences->>'max_distance_km')::INTEGER;
            IF v_max_dist <= 0 OR v_max_dist > 500 THEN
                RAISE EXCEPTION 'Invalid discovery preference: max_distance_km must be between 1 and 500.';
            END IF;
        END IF;
    END IF;

    -- 5. Validate all interests against public.interests before touching the database
    IF p_interests IS NOT NULL THEN
        FOREACH v_interest_name IN ARRAY p_interests LOOP
            v_interest_name := TRIM(v_interest_name);
            IF v_interest_name = '' THEN
                CONTINUE;
            END IF;

            -- Check duplicate
            IF lower(v_interest_name) = ANY(v_seen_interests) THEN
                RAISE EXCEPTION 'Duplicate interest provided: %.', v_interest_name;
            END IF;
            v_seen_interests := array_append(v_seen_interests, lower(v_interest_name));

            -- Check existence in reference table
            SELECT id INTO v_interest_id
              FROM public.interests
             WHERE lower(name) = lower(v_interest_name)
             LIMIT 1;

            IF v_interest_id IS NULL THEN
                RAISE EXCEPTION 'Invalid or unknown interest: %.', v_interest_name;
            END IF;

            v_interest_ids := array_append(v_interest_ids, v_interest_id);
        END LOOP;
    END IF;

    -- 6. Validate primary intention
    IF p_primary_intent IS NULL OR TRIM(p_primary_intent) = '' THEN
        RAISE EXCEPTION 'A primary connection intention is required.';
    END IF;

    SELECT id INTO v_primary_intent_id
      FROM public.intentions
     WHERE lower(name) = lower(TRIM(p_primary_intent))
     LIMIT 1;

    IF v_primary_intent_id IS NULL THEN
        RAISE EXCEPTION 'Invalid primary intention: %.', p_primary_intent;
    END IF;
    v_seen_intentions := array_append(v_seen_intentions, lower(TRIM(p_primary_intent)));

    -- 7. Validate secondary intentions
    IF p_secondary_intents IS NOT NULL THEN
        FOREACH v_secondary_name IN ARRAY p_secondary_intents LOOP
            v_secondary_name := TRIM(v_secondary_name);
            IF v_secondary_name = '' THEN
                CONTINUE;
            END IF;

            IF lower(v_secondary_name) = lower(TRIM(p_primary_intent)) THEN
                RAISE EXCEPTION 'Secondary intentions cannot include the primary intention.';
            END IF;

            IF lower(v_secondary_name) = ANY(v_seen_intentions) THEN
                RAISE EXCEPTION 'Duplicate intention provided: %.', v_secondary_name;
            END IF;
            v_seen_intentions := array_append(v_seen_intentions, lower(v_secondary_name));

            SELECT id INTO v_secondary_id
              FROM public.intentions
             WHERE lower(name) = lower(v_secondary_name)
             LIMIT 1;

            IF v_secondary_id IS NULL THEN
                RAISE EXCEPTION 'Invalid secondary intention: %.', v_secondary_name;
            END IF;

            v_secondary_ids := array_append(v_secondary_ids, v_secondary_id);
        END LOOP;
    END IF;

    -- ──────────────────────────────────────────────────────────────────────────
    -- All validation succeeded! Execute atomic database modifications.
    -- ──────────────────────────────────────────────────────────────────────────

    -- A. Update public.profiles
    -- (User cannot modify id, is_verified, is_suspended, or date_of_birth)
    UPDATE public.profiles
       SET display_name = TRIM(p_display_name),
           avatar_url   = NULLIF(TRIM(p_avatar_url), ''),
           bio          = TRIM(p_bio),
           city         = TRIM(p_city),
           updated_at   = now()
     WHERE id = v_uid;

    -- B. Atomically replace profile_interests
    DELETE FROM public.profile_interests WHERE profile_id = v_uid;
    IF array_length(v_interest_ids, 1) > 0 THEN
        INSERT INTO public.profile_interests (profile_id, interest_id)
        SELECT v_uid, unnest(v_interest_ids);
    END IF;

    -- C. Atomically replace profile_intentions (strictly 1 primary)
    DELETE FROM public.profile_intentions WHERE profile_id = v_uid;
    INSERT INTO public.profile_intentions (profile_id, intention_id, is_primary)
    VALUES (v_uid, v_primary_intent_id, TRUE);

    IF array_length(v_secondary_ids, 1) > 0 THEN
        INSERT INTO public.profile_intentions (profile_id, intention_id, is_primary)
        SELECT v_uid, unnest(v_secondary_ids), FALSE;
    END IF;

    -- D. Safely upsert profile_private
    INSERT INTO public.profile_private (
        user_id,
        age_verified,
        preferred_activity_categories,
        discovery_preferences,
        created_at
    )
    VALUES (
        v_uid,
        FALSE,
        COALESCE(p_preferred_categories, '{}'),
        COALESCE(p_discovery_preferences, '{}'::jsonb),
        now()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        preferred_activity_categories = COALESCE(p_preferred_categories, profile_private.preferred_activity_categories),
        discovery_preferences = COALESCE(p_discovery_preferences, profile_private.discovery_preferences);

    RETURN jsonb_build_object(
        'success', TRUE,
        'message', 'Profile updated successfully.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.update_user_profile(TEXT, TEXT, TEXT, TEXT, TEXT[], TEXT, TEXT[], TEXT[], JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_user_profile(TEXT, TEXT, TEXT, TEXT, TEXT[], TEXT, TEXT[], TEXT[], JSONB) TO authenticated;


-- 4. Hardened submit_user_report RPC
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
    v_clean_type   TEXT;
    v_allowed_reasons TEXT[] := ARRAY[
        'Inappropriate or offensive behavior',
        'Harassment or unwanted contact',
        'Hate speech or discrimination',
        'Commercial solicitation or spam',
        'Misrepresentation or fake profile',
        'Safety concern at an activity',
        'No-show or unexcused absence',
        'Non-consensual contact or privacy violation',
        'Other community guideline concern'
    ];
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    IF p_reported_user_id IS NULL OR p_reported_user_id = v_uid THEN
        RAISE EXCEPTION 'Invalid reported user: cannot report yourself.';
    END IF;

    -- Strict reason allowlist check
    v_clean_reason := TRIM(COALESCE(p_reason, ''));
    IF NOT (v_clean_reason = ANY(v_allowed_reasons)) THEN
        RAISE EXCEPTION 'Invalid report reason: "%". Must be one of the canonical community reasons.', v_clean_reason;
    END IF;

    -- Description length limit
    v_clean_desc := TRIM(p_description);
    IF v_clean_desc IS NOT NULL AND LENGTH(v_clean_desc) > 500 THEN
        RAISE EXCEPTION 'Description exceeds maximum length of 500 characters.';
    END IF;

    -- Content type validation
    v_clean_type := lower(TRIM(COALESCE(p_content_type, 'profile')));
    IF v_clean_type NOT IN ('profile', 'message', 'experience', 'comment', 'other') THEN
        RAISE EXCEPTION 'Invalid content type: %.', p_content_type;
    END IF;

    -- Verify reported user exists in public.profiles
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_reported_user_id) THEN
        RAISE EXCEPTION 'Reported user does not exist.';
    END IF;

    -- Validate content relationship where specified
    IF p_content_id IS NOT NULL THEN
        IF v_clean_type = 'message' THEN
            IF NOT EXISTS (
                SELECT 1 FROM public.messages
                 WHERE id = p_content_id AND sender_id = p_reported_user_id
            ) THEN
                RAISE EXCEPTION 'Reported message does not exist or does not belong to the reported user.';
            END IF;
        ELSIF v_clean_type = 'experience' THEN
            IF NOT EXISTS (
                SELECT 1 FROM public.experiences
                 WHERE id = p_content_id AND host_id = p_reported_user_id
            ) THEN
                RAISE EXCEPTION 'Reported experience does not exist or does not belong to the reported user.';
            END IF;
        END IF;
    END IF;

    -- Prevent duplicate accidental submissions within 1 hour
    IF EXISTS (
        SELECT 1 FROM public.reports
         WHERE reporter_id = v_uid
           AND reported_user_id = p_reported_user_id
           AND reason = v_clean_reason
           AND status = 'pending'
           AND created_at > (now() - interval '1 hour')
    ) THEN
        RAISE EXCEPTION 'A pending report for this member with the same reason was recently submitted. Our moderation team is already reviewing it.';
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
        v_clean_type,
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
        'message', 'Report submitted successfully. Thank you for helping keep MELSAVA safe.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.submit_user_report(UUID, TEXT, TEXT, TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_user_report(UUID, TEXT, TEXT, TEXT, UUID) TO authenticated;


-- 5. Hardened block_user and unblock_user RPCs
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

    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_blocked_id) THEN
        RAISE EXCEPTION 'Target user does not exist.';
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


-- 6. Privacy Settings Persistence RPCs
DROP FUNCTION IF EXISTS public.update_privacy_settings(JSONB);

CREATE OR REPLACE FUNCTION public.update_privacy_settings(p_settings JSONB)
RETURNS JSONB
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

    INSERT INTO public.profile_private (user_id, age_verified, privacy_settings, created_at)
    VALUES (v_uid, FALSE, p_settings, now())
    ON CONFLICT (user_id) DO UPDATE SET
        privacy_settings = p_settings;

    RETURN jsonb_build_object(
        'success', TRUE,
        'privacy_settings', p_settings
    );
END;
$$;

REVOKE ALL ON FUNCTION public.update_privacy_settings(JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_privacy_settings(JSONB) TO authenticated;


DROP FUNCTION IF EXISTS public.get_privacy_settings();

CREATE OR REPLACE FUNCTION public.get_privacy_settings()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_settings JSONB;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    SELECT privacy_settings INTO v_settings
      FROM public.profile_private
     WHERE user_id = v_uid;

    RETURN COALESCE(v_settings, '{"public_radar": true, "ghost_mode": false, "show_city": true}'::jsonb);
END;
$$;

REVOKE ALL ON FUNCTION public.get_privacy_settings() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_privacy_settings() TO authenticated;
