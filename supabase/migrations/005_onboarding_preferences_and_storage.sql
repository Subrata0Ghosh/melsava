-- ============================================================================
-- MELSAVA Dating App — Onboarding Preferences & Avatar Storage
-- Migration: 005_onboarding_preferences_and_storage.sql
-- Description: Extends existing profile_private with onboarding preference
--              columns (no duplicate tables) and configures the public
--              `avatars` Supabase Storage bucket with per-user RLS policies.
-- ============================================================================

-- 1. Extend existing public.profile_private for activity, availability,
--    and discovery preferences collected during profile onboarding.
ALTER TABLE public.profile_private
    ADD COLUMN IF NOT EXISTS preferred_activity_categories TEXT[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS availability_preferences JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS discovery_preferences JSONB NOT NULL DEFAULT '{}'::jsonb;

-- 2. Ensure handle signup trigger supports Google/OAuth display names too
CREATE OR REPLACE FUNCTION public.create_profile_on_signup()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_display_name TEXT;
BEGIN
    v_display_name := COALESCE(
        NULLIF(TRIM(NEW.raw_user_meta_data ->> 'display_name'), ''),
        NULLIF(TRIM(NEW.raw_user_meta_data ->> 'full_name'), ''),
        NULLIF(TRIM(NEW.raw_user_meta_data ->> 'name'), ''),
        NULLIF(split_part(COALESCE(NEW.email, ''), '@', 1), ''),
        'New User'
    );

    -- Enforce 2..50 char constraint safely
    IF char_length(v_display_name) < 2 THEN
        v_display_name := 'MELSAVA Member';
    ELSIF char_length(v_display_name) > 50 THEN
        v_display_name := left(v_display_name, 50);
    END IF;

    INSERT INTO public.profiles (id, display_name, avatar_url, created_at, updated_at)
    VALUES (
        NEW.id,
        v_display_name,
        COALESCE(
            NEW.raw_user_meta_data ->> 'avatar_url',
            NEW.raw_user_meta_data ->> 'picture'
        ),
        now(),
        now()
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.profile_private (user_id, email, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        now()
    )
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$;

-- 3. Create public `avatars` storage bucket for profile photo uploads
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    TRUE,
    5242880, -- 5 MB max
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 4. Storage RLS Policies for `avatars` bucket
--    Public read for profile photos; write/update/delete restricted to own folder `<auth.uid()>/...`
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'avatars_public_read'
    ) THEN
        CREATE POLICY "avatars_public_read"
            ON storage.objects FOR SELECT
            USING (bucket_id = 'avatars');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'avatars_insert_own'
    ) THEN
        CREATE POLICY "avatars_insert_own"
            ON storage.objects FOR INSERT
            TO authenticated
            WITH CHECK (
                bucket_id = 'avatars'
                AND (storage.foldername(name))[1] = auth.uid()::text
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'avatars_update_own'
    ) THEN
        CREATE POLICY "avatars_update_own"
            ON storage.objects FOR UPDATE
            TO authenticated
            USING (
                bucket_id = 'avatars'
                AND (storage.foldername(name))[1] = auth.uid()::text
            )
            WITH CHECK (
                bucket_id = 'avatars'
                AND (storage.foldername(name))[1] = auth.uid()::text
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'avatars_delete_own'
    ) THEN
        CREATE POLICY "avatars_delete_own"
            ON storage.objects FOR DELETE
            TO authenticated
            USING (
                bucket_id = 'avatars'
                AND (storage.foldername(name))[1] = auth.uid()::text
            );
    END IF;
END $$;
