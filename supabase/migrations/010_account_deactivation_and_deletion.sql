-- ============================================================================
-- MELSAVA - Account Deactivation & Permanent Deletion
-- Migration: 010_account_deactivation_and_deletion.sql
-- Description:
--   1. Adds `is_deactivated` and `deactivated_at` columns to `public.profiles`.
--   2. Implements `deactivate_user_account()` RPC: hides the user from public feeds and marks account paused.
--   3. Implements `reactivate_user_account()` RPC: unpauses the account upon next login.
--   4. Implements `delete_user_account()` RPC: permanently deletes all profile records (cascading
--      across all foreign keys) and purges the user credentials from `auth.users`.
-- ============================================================================

-- 1. Add deactivation columns
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS is_deactivated BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS deactivated_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_profiles_is_deactivated 
    ON public.profiles(is_deactivated) 
    WHERE is_deactivated = TRUE;

-- 2. Temporary Account Deactivation
CREATE OR REPLACE FUNCTION public.deactivate_user_account()
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

    UPDATE public.profiles
       SET is_deactivated = TRUE,
           deactivated_at = now(),
           updated_at = now()
     WHERE id = v_uid;

    RETURN jsonb_build_object(
        'success', TRUE,
        'status', 'deactivated',
        'message', 'Account temporarily deactivated. Reactivate anytime by logging back in.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.deactivate_user_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.deactivate_user_account() TO authenticated;

-- 3. Account Reactivation (called on sign in if account was paused)
CREATE OR REPLACE FUNCTION public.reactivate_user_account()
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

    UPDATE public.profiles
       SET is_deactivated = FALSE,
           deactivated_at = NULL,
           updated_at = now()
     WHERE id = v_uid;

    RETURN jsonb_build_object(
        'success', TRUE,
        'status', 'active',
        'message', 'Welcome back! Your account has been reactivated.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.reactivate_user_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reactivate_user_account() TO authenticated;

-- 4. Permanent Account Deletion
CREATE OR REPLACE FUNCTION public.delete_user_account()
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

    -- Delete from profiles (cascades to profile_private, profile_interests, profile_intentions,
    -- experience_members, post_experience_choices, connections, conversation_members, app_notifications)
    DELETE FROM public.profiles WHERE id = v_uid;

    -- Delete from auth.users to completely delete credentials and active tokens
    DELETE FROM auth.users WHERE id = v_uid;

    RETURN jsonb_build_object(
        'success', TRUE,
        'status', 'deleted',
        'message', 'Your account and all associated data have been permanently deleted.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
