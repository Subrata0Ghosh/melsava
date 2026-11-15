-- ============================================================================
-- MELSAVA Dating App — Initial Database Schema
-- Migration: 001_initial_schema.sql
-- Description: Creates all 21 tables with UUID PKs, timestamps, FKs,
--              constraints, and indexes.
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. profiles
-- ============================================================================
CREATE TABLE public.profiles (
    id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name  TEXT NOT NULL CHECK (char_length(display_name) BETWEEN 2 AND 50),
    avatar_url    TEXT,
    bio           TEXT CHECK (char_length(bio) <= 500),
    city          TEXT,
    is_verified   BOOLEAN NOT NULL DEFAULT FALSE,
    is_suspended  BOOLEAN NOT NULL DEFAULT FALSE,
    onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_profiles_city ON public.profiles(city);
CREATE INDEX idx_profiles_is_verified ON public.profiles(is_verified) WHERE is_verified = TRUE;

-- ============================================================================
-- 2. profile_private
-- ============================================================================
CREATE TABLE public.profile_private (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    date_of_birth           DATE,
    email                   TEXT,
    age_verified            BOOLEAN NOT NULL DEFAULT FALSE,
    terms_accepted_at       TIMESTAMPTZ,
    guidelines_accepted_at  TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_profile_private_user_id ON public.profile_private(user_id);

-- ============================================================================
-- 3. interests
-- ============================================================================
CREATE TABLE public.interests (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL UNIQUE,
    icon       TEXT,
    category   TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_interests_category ON public.interests(category);

-- ============================================================================
-- 4. profile_interests
-- ============================================================================
CREATE TABLE public.profile_interests (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    interest_id UUID NOT NULL REFERENCES public.interests(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (profile_id, interest_id)
);

CREATE INDEX idx_profile_interests_profile_id ON public.profile_interests(profile_id);
CREATE INDEX idx_profile_interests_interest_id ON public.profile_interests(interest_id);

-- ============================================================================
-- 5. intentions
-- ============================================================================
CREATE TABLE public.intentions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL UNIQUE,
    description TEXT,
    category    TEXT NOT NULL CHECK (category IN ('friendship', 'dating')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 6. profile_intentions
-- ============================================================================
CREATE TABLE public.profile_intentions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    intention_id UUID NOT NULL REFERENCES public.intentions(id) ON DELETE CASCADE,
    is_primary   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (profile_id, intention_id)
);

CREATE INDEX idx_profile_intentions_profile_id ON public.profile_intentions(profile_id);

-- ============================================================================
-- 7. activity_categories
-- ============================================================================
CREATE TABLE public.activity_categories (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT NOT NULL UNIQUE,
    description   TEXT,
    icon          TEXT,
    color         TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_activity_categories_display_order ON public.activity_categories(display_order);

-- ============================================================================
-- 8. experiences
-- ============================================================================
CREATE TYPE public.experience_status AS ENUM ('draft', 'published', 'completed', 'cancelled');

CREATE TABLE public.experiences (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title               TEXT NOT NULL CHECK (char_length(title) BETWEEN 3 AND 120),
    description         TEXT,
    cover_image_url     TEXT,
    category_id         UUID REFERENCES public.activity_categories(id) ON DELETE SET NULL,
    host_id             UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    city                TEXT,
    venue_name          TEXT,
    venue_address       TEXT,
    is_online           BOOLEAN NOT NULL DEFAULT FALSE,
    max_participants    INTEGER CHECK (max_participants > 0),
    status              public.experience_status NOT NULL DEFAULT 'draft',
    starts_at           TIMESTAMPTZ,
    ends_at             TIMESTAMPTZ,
    duration_minutes    INTEGER CHECK (duration_minutes > 0),
    cancellation_policy TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_experience_dates CHECK (ends_at IS NULL OR ends_at > starts_at)
);

CREATE INDEX idx_experiences_host_id ON public.experiences(host_id);
CREATE INDEX idx_experiences_category_id ON public.experiences(category_id);
CREATE INDEX idx_experiences_status ON public.experiences(status);
CREATE INDEX idx_experiences_city ON public.experiences(city);
CREATE INDEX idx_experiences_starts_at ON public.experiences(starts_at);

-- ============================================================================
-- 9. experience_sessions
-- ============================================================================
CREATE TABLE public.experience_sessions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experience_id UUID NOT NULL REFERENCES public.experiences(id) ON DELETE CASCADE,
    session_date  TIMESTAMPTZ NOT NULL,
    status        TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_experience_sessions_experience_id ON public.experience_sessions(experience_id);
CREATE INDEX idx_experience_sessions_session_date ON public.experience_sessions(session_date);

-- ============================================================================
-- 10. experience_members
-- ============================================================================
CREATE TYPE public.member_status AS ENUM ('joined', 'waitlisted', 'cancelled', 'attended');

CREATE TABLE public.experience_members (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experience_id UUID NOT NULL REFERENCES public.experiences(id) ON DELETE CASCADE,
    user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status        public.member_status NOT NULL DEFAULT 'joined',
    joined_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    cancelled_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (experience_id, user_id)
);

CREATE INDEX idx_experience_members_experience_id ON public.experience_members(experience_id);
CREATE INDEX idx_experience_members_user_id ON public.experience_members(user_id);
CREATE INDEX idx_experience_members_status ON public.experience_members(status);

-- ============================================================================
-- 11. experience_prompts
-- ============================================================================
CREATE TABLE public.experience_prompts (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experience_id UUID NOT NULL REFERENCES public.experiences(id) ON DELETE CASCADE,
    prompt_text   TEXT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_experience_prompts_experience_id ON public.experience_prompts(experience_id);

-- ============================================================================
-- 12. experience_answers
-- ============================================================================
CREATE TABLE public.experience_answers (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prompt_id   UUID NOT NULL REFERENCES public.experience_prompts(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    answer_text TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (prompt_id, user_id)
);

CREATE INDEX idx_experience_answers_prompt_id ON public.experience_answers(prompt_id);
CREATE INDEX idx_experience_answers_user_id ON public.experience_answers(user_id);

-- ============================================================================
-- 13. post_experience_choices
-- ============================================================================
CREATE TYPE public.choice_type AS ENUM ('friendship', 'activity_partner', 'explore_dating', 'no_connection');

CREATE TABLE public.post_experience_choices (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experience_id UUID NOT NULL REFERENCES public.experiences(id) ON DELETE CASCADE,
    chooser_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    chosen_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    choice_type   public.choice_type NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (experience_id, chooser_id, chosen_id),
    CONSTRAINT chk_no_self_choice CHECK (chooser_id != chosen_id)
);

CREATE INDEX idx_pec_experience_id ON public.post_experience_choices(experience_id);
CREATE INDEX idx_pec_chooser_id ON public.post_experience_choices(chooser_id);
CREATE INDEX idx_pec_chosen_id ON public.post_experience_choices(chosen_id);

-- ============================================================================
-- 14. connections
-- ============================================================================
CREATE TABLE public.connections (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_b_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    connection_type TEXT NOT NULL,
    experience_id   UUID REFERENCES public.experiences(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_a_id, user_b_id),
    CONSTRAINT chk_no_self_connection CHECK (user_a_id != user_b_id),
    CONSTRAINT chk_user_order CHECK (user_a_id < user_b_id)
);

CREATE INDEX idx_connections_user_a_id ON public.connections(user_a_id);
CREATE INDEX idx_connections_user_b_id ON public.connections(user_b_id);
CREATE INDEX idx_connections_experience_id ON public.connections(experience_id);

-- ============================================================================
-- 15. conversations
-- ============================================================================
CREATE TABLE public.conversations (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    connection_id UUID UNIQUE REFERENCES public.connections(id) ON DELETE SET NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_conversations_connection_id ON public.conversations(connection_id);

-- ============================================================================
-- 16. conversation_members
-- ============================================================================
CREATE TABLE public.conversation_members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (conversation_id, user_id)
);

CREATE INDEX idx_conversation_members_conversation_id ON public.conversation_members(conversation_id);
CREATE INDEX idx_conversation_members_user_id ON public.conversation_members(user_id);

-- ============================================================================
-- 17. messages
-- ============================================================================
CREATE TABLE public.messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content         TEXT NOT NULL CHECK (char_length(content) > 0),
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX idx_messages_unread ON public.messages(conversation_id, is_read) WHERE is_read = FALSE;

-- ============================================================================
-- 18. blocks
-- ============================================================================
CREATE TABLE public.blocks (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason     TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (blocker_id, blocked_id),
    CONSTRAINT chk_no_self_block CHECK (blocker_id != blocked_id)
);

CREATE INDEX idx_blocks_blocker_id ON public.blocks(blocker_id);
CREATE INDEX idx_blocks_blocked_id ON public.blocks(blocked_id);

-- ============================================================================
-- 19. reports
-- ============================================================================
CREATE TYPE public.report_status AS ENUM ('pending', 'reviewed', 'resolved', 'dismissed');

CREATE TABLE public.reports (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id           UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_content_type TEXT,
    reported_content_id   UUID,
    reason                TEXT NOT NULL,
    description           TEXT,
    status                public.report_status NOT NULL DEFAULT 'pending',
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at           TIMESTAMPTZ,
    CONSTRAINT chk_no_self_report CHECK (reporter_id != reported_user_id)
);

CREATE INDEX idx_reports_reporter_id ON public.reports(reporter_id);
CREATE INDEX idx_reports_reported_user_id ON public.reports(reported_user_id);
CREATE INDEX idx_reports_status ON public.reports(status);

-- ============================================================================
-- 20. moderation_actions
-- ============================================================================
CREATE TYPE public.moderation_action_type AS ENUM ('warning', 'suspension', 'ban');

CREATE TABLE public.moderation_actions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    action_type  public.moderation_action_type NOT NULL,
    reason       TEXT NOT NULL,
    performed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at   TIMESTAMPTZ
);

CREATE INDEX idx_moderation_actions_user_id ON public.moderation_actions(user_id);
CREATE INDEX idx_moderation_actions_action_type ON public.moderation_actions(action_type);

-- ============================================================================
-- 21. device_tokens
-- ============================================================================
CREATE TABLE public.device_tokens (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    token      TEXT NOT NULL,
    platform   TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, token)
);

CREATE INDEX idx_device_tokens_user_id ON public.device_tokens(user_id);

-- ============================================================================
-- Auto-update updated_at trigger function
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to tables that have updated_at
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.experiences
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.conversations
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
-- ============================================================================
-- MELSAVA Dating App — Row Level Security Policies
-- Migration: 002_rls_policies.sql
-- Description: Enables RLS on all 21 tables and creates granular access
--              policies based on authenticated user context.
-- ============================================================================

-- ============================================================================
-- Enable RLS on ALL tables
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_private ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intentions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_intentions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experiences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experience_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experience_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experience_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experience_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_experience_choices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 1. profiles — Anyone can read public profiles; users can update own
-- ============================================================================
CREATE POLICY "profiles_select_public"
    ON public.profiles FOR SELECT
    USING (TRUE);

CREATE POLICY "profiles_insert_own"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================================================
-- 2. profile_private — Only own user can read/update
-- ============================================================================
CREATE POLICY "profile_private_select_own"
    ON public.profile_private FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "profile_private_insert_own"
    ON public.profile_private FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "profile_private_update_own"
    ON public.profile_private FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 3. interests — Anyone can read (reference data)
-- ============================================================================
CREATE POLICY "interests_select_all"
    ON public.interests FOR SELECT
    USING (TRUE);

-- ============================================================================
-- 4. profile_interests — Anyone can read; users can manage own
-- ============================================================================
CREATE POLICY "profile_interests_select_all"
    ON public.profile_interests FOR SELECT
    USING (TRUE);

CREATE POLICY "profile_interests_insert_own"
    ON public.profile_interests FOR INSERT
    WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "profile_interests_delete_own"
    ON public.profile_interests FOR DELETE
    USING (auth.uid() = profile_id);

-- ============================================================================
-- 5. intentions — Anyone can read (reference data)
-- ============================================================================
CREATE POLICY "intentions_select_all"
    ON public.intentions FOR SELECT
    USING (TRUE);

-- ============================================================================
-- 6. profile_intentions — Anyone can read; users can manage own
-- ============================================================================
CREATE POLICY "profile_intentions_select_all"
    ON public.profile_intentions FOR SELECT
    USING (TRUE);

CREATE POLICY "profile_intentions_insert_own"
    ON public.profile_intentions FOR INSERT
    WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "profile_intentions_delete_own"
    ON public.profile_intentions FOR DELETE
    USING (auth.uid() = profile_id);

CREATE POLICY "profile_intentions_update_own"
    ON public.profile_intentions FOR UPDATE
    USING (auth.uid() = profile_id)
    WITH CHECK (auth.uid() = profile_id);

-- ============================================================================
-- 7. activity_categories — Anyone can read (reference data)
-- ============================================================================
CREATE POLICY "activity_categories_select_all"
    ON public.activity_categories FOR SELECT
    USING (TRUE);

-- ============================================================================
-- 8. experiences — Anyone can read published; hosts can manage own
-- ============================================================================
CREATE POLICY "experiences_select_published"
    ON public.experiences FOR SELECT
    USING (status = 'published' OR auth.uid() = host_id);

CREATE POLICY "experiences_insert_own"
    ON public.experiences FOR INSERT
    WITH CHECK (auth.uid() = host_id);

CREATE POLICY "experiences_update_own"
    ON public.experiences FOR UPDATE
    USING (auth.uid() = host_id)
    WITH CHECK (auth.uid() = host_id);

CREATE POLICY "experiences_delete_own"
    ON public.experiences FOR DELETE
    USING (auth.uid() = host_id);

-- ============================================================================
-- 9. experience_sessions — Same visibility as parent experience
-- ============================================================================
CREATE POLICY "experience_sessions_select"
    ON public.experience_sessions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.experiences e
            WHERE e.id = experience_id
              AND (e.status = 'published' OR e.host_id = auth.uid())
        )
    );

CREATE POLICY "experience_sessions_insert_host"
    ON public.experience_sessions FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.experiences e
            WHERE e.id = experience_id AND e.host_id = auth.uid()
        )
    );

CREATE POLICY "experience_sessions_update_host"
    ON public.experience_sessions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.experiences e
            WHERE e.id = experience_id AND e.host_id = auth.uid()
        )
    );

-- ============================================================================
-- 10. experience_members — Users can read experiences they joined; can join/cancel own
-- ============================================================================
CREATE POLICY "experience_members_select"
    ON public.experience_members FOR SELECT
    USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM public.experiences e
            WHERE e.id = experience_id AND e.host_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.experience_members em2
            WHERE em2.experience_id = experience_members.experience_id
              AND em2.user_id = auth.uid()
              AND em2.status IN ('joined', 'attended')
        )
    );

CREATE POLICY "experience_members_insert_own"
    ON public.experience_members FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "experience_members_update_own"
    ON public.experience_members FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 11. experience_prompts — Visible to experience members and host
-- ============================================================================
CREATE POLICY "experience_prompts_select"
    ON public.experience_prompts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.experiences e
            WHERE e.id = experience_id
              AND (e.status = 'published' OR e.host_id = auth.uid())
        )
    );

CREATE POLICY "experience_prompts_insert_host"
    ON public.experience_prompts FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.experiences e
            WHERE e.id = experience_id AND e.host_id = auth.uid()
        )
    );

-- ============================================================================
-- 12. experience_answers — User can manage own answers; host can read all for their experience
-- ============================================================================
CREATE POLICY "experience_answers_select"
    ON public.experience_answers FOR SELECT
    USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM public.experience_prompts ep
            JOIN public.experiences e ON e.id = ep.experience_id
            WHERE ep.id = prompt_id AND e.host_id = auth.uid()
        )
    );

CREATE POLICY "experience_answers_insert_own"
    ON public.experience_answers FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "experience_answers_update_own"
    ON public.experience_answers FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 13. post_experience_choices — Only chooser can insert/read own choices
-- ============================================================================
CREATE POLICY "pec_select_own"
    ON public.post_experience_choices FOR SELECT
    USING (auth.uid() = chooser_id);

CREATE POLICY "pec_insert_own"
    ON public.post_experience_choices FOR INSERT
    WITH CHECK (auth.uid() = chooser_id);

-- ============================================================================
-- 14. connections — Only connected users can read
-- ============================================================================
CREATE POLICY "connections_select_own"
    ON public.connections FOR SELECT
    USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);

-- ============================================================================
-- 15. conversations — Only members can read
-- ============================================================================
CREATE POLICY "conversations_select_member"
    ON public.conversations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.conversation_members cm
            WHERE cm.conversation_id = id AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "conversations_update_member"
    ON public.conversations FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.conversation_members cm
            WHERE cm.conversation_id = id AND cm.user_id = auth.uid()
        )
    );

-- ============================================================================
-- 16. conversation_members — Only members can read
-- ============================================================================
CREATE POLICY "conversation_members_select"
    ON public.conversation_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.conversation_members cm2
            WHERE cm2.conversation_id = conversation_id
              AND cm2.user_id = auth.uid()
        )
    );

-- ============================================================================
-- 17. messages — Only conversation members can read; sender can insert
-- ============================================================================
CREATE POLICY "messages_select_member"
    ON public.messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.conversation_members cm
            WHERE cm.conversation_id = conversation_id
              AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "messages_insert_sender"
    ON public.messages FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id
        AND EXISTS (
            SELECT 1 FROM public.conversation_members cm
            WHERE cm.conversation_id = conversation_id
              AND cm.user_id = auth.uid()
        )
    );

CREATE POLICY "messages_update_read"
    ON public.messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.conversation_members cm
            WHERE cm.conversation_id = conversation_id
              AND cm.user_id = auth.uid()
        )
    );

-- ============================================================================
-- 18. blocks — Only blocker can manage
-- ============================================================================
CREATE POLICY "blocks_select_own"
    ON public.blocks FOR SELECT
    USING (auth.uid() = blocker_id);

CREATE POLICY "blocks_insert_own"
    ON public.blocks FOR INSERT
    WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "blocks_delete_own"
    ON public.blocks FOR DELETE
    USING (auth.uid() = blocker_id);

-- ============================================================================
-- 19. reports — Only reporter can insert; cannot read others'
-- ============================================================================
CREATE POLICY "reports_select_own"
    ON public.reports FOR SELECT
    USING (auth.uid() = reporter_id);

CREATE POLICY "reports_insert_own"
    ON public.reports FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);

-- ============================================================================
-- 20. moderation_actions — Only the moderated user can read own (not modify)
-- ============================================================================
CREATE POLICY "moderation_actions_select_own"
    ON public.moderation_actions FOR SELECT
    USING (auth.uid() = user_id);

-- ============================================================================
-- 21. device_tokens — Only own user
-- ============================================================================
CREATE POLICY "device_tokens_select_own"
    ON public.device_tokens FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "device_tokens_insert_own"
    ON public.device_tokens FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "device_tokens_update_own"
    ON public.device_tokens FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "device_tokens_delete_own"
    ON public.device_tokens FOR DELETE
    USING (auth.uid() = user_id);
-- ============================================================================
-- MELSAVA Dating App — Server-Side Functions & Triggers
-- Migration: 003_functions.sql
-- Description: Core business-logic functions executed server-side for
--              atomicity and security.
-- ============================================================================

-- ============================================================================
-- 1. create_profile_on_signup()
--    Trigger function: auto-creates a profiles row when a new user is
--    inserted into auth.users.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.create_profile_on_signup()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data ->> 'display_name', 'New User'),
        now(),
        now()
    );

    INSERT INTO public.profile_private (user_id, email, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        now()
    );

    RETURN NEW;
END;
$$;

-- Attach trigger to auth.users
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.create_profile_on_signup();

-- ============================================================================
-- 2. check_experience_capacity(experience_id UUID)
--    Returns whether there is room for another participant.
--    Returns a JSON object: { "has_capacity": bool, "current": int, "max": int|null }
-- ============================================================================
CREATE OR REPLACE FUNCTION public.check_experience_capacity(p_experience_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
AS $$
DECLARE
    v_max_participants INTEGER;
    v_current_count    INTEGER;
BEGIN
    -- Get max participants for the experience
    SELECT max_participants
      INTO v_max_participants
      FROM public.experiences
     WHERE id = p_experience_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Experience not found: %', p_experience_id;
    END IF;

    -- Count current active members (joined or waitlisted, not cancelled)
    SELECT COUNT(*)
      INTO v_current_count
      FROM public.experience_members
     WHERE experience_id = p_experience_id
       AND status IN ('joined', 'attended');

    -- If max_participants is NULL, capacity is unlimited
    RETURN jsonb_build_object(
        'has_capacity', (v_max_participants IS NULL OR v_current_count < v_max_participants),
        'current_count', v_current_count,
        'max_participants', v_max_participants
    );
END;
$$;

-- ============================================================================
-- 3. process_mutual_connections(experience_id UUID)
--    Atomic function that:
--    a) Finds all mutual positive choice pairs for a given experience
--       (both users chose something other than 'no_connection' for each other)
--    b) Creates connections where mutual interest exists
--    c) Creates conversations for each new connection
--    d) Returns the created connections
--
--    IDEMPOTENT: Skips pairs that already have a connection.
--    TRANSACTIONAL: Runs in a single transaction — all or nothing.
-- ============================================================================
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
DECLARE
    v_pair         RECORD;
    v_conn_id      UUID;
    v_conv_id      UUID;
    v_conn_type    TEXT;
    v_user_a       UUID;
    v_user_b       UUID;
BEGIN
    -- Verify experience exists and is completed
    IF NOT EXISTS (
        SELECT 1 FROM public.experiences
        WHERE id = p_experience_id
    ) THEN
        RAISE EXCEPTION 'Experience not found: %', p_experience_id;
    END IF;

    -- Find mutual positive choices (both chose something other than no_connection)
    FOR v_pair IN
        SELECT
            c1.chooser_id AS user_1,
            c1.chosen_id  AS user_2,
            c1.choice_type AS choice_1,
            c2.choice_type AS choice_2
        FROM public.post_experience_choices c1
        JOIN public.post_experience_choices c2
            ON c1.experience_id = c2.experience_id
           AND c1.chooser_id = c2.chosen_id
           AND c1.chosen_id = c2.chooser_id
        WHERE c1.experience_id = p_experience_id
          AND c1.choice_type != 'no_connection'
          AND c2.choice_type != 'no_connection'
          -- Only process each pair once (lower UUID first)
          AND c1.chooser_id < c1.chosen_id
    LOOP
        -- Normalize user order (user_a < user_b) to match unique constraint
        IF v_pair.user_1 < v_pair.user_2 THEN
            v_user_a := v_pair.user_1;
            v_user_b := v_pair.user_2;
        ELSE
            v_user_a := v_pair.user_2;
            v_user_b := v_pair.user_1;
        END IF;

        -- Determine connection type: use the "stronger" / more romantic type
        -- Priority: explore_dating > activity_partner > friendship
        IF v_pair.choice_1 = 'explore_dating' OR v_pair.choice_2 = 'explore_dating' THEN
            v_conn_type := 'explore_dating';
        ELSIF v_pair.choice_1 = 'activity_partner' OR v_pair.choice_2 = 'activity_partner' THEN
            v_conn_type := 'activity_partner';
        ELSE
            v_conn_type := 'friendship';
        END IF;

        -- IDEMPOTENT: Skip if connection already exists
        SELECT c.id INTO v_conn_id
          FROM public.connections c
         WHERE c.user_a_id = v_user_a
           AND c.user_b_id = v_user_b;

        IF v_conn_id IS NOT NULL THEN
            -- Connection already exists; get its conversation
            SELECT conv.id INTO v_conv_id
              FROM public.conversations conv
             WHERE conv.connection_id = v_conn_id;

            connection_id   := v_conn_id;
            user_a          := v_user_a;
            user_b          := v_user_b;
            connection_type := v_conn_type;
            conversation_id := v_conv_id;
            RETURN NEXT;
            CONTINUE;
        END IF;

        -- Create connection
        INSERT INTO public.connections (user_a_id, user_b_id, connection_type, experience_id)
        VALUES (v_user_a, v_user_b, v_conn_type, p_experience_id)
        RETURNING id INTO v_conn_id;

        -- Create conversation for this connection
        INSERT INTO public.conversations (connection_id)
        VALUES (v_conn_id)
        RETURNING id INTO v_conv_id;

        -- Add both users as conversation members
        INSERT INTO public.conversation_members (conversation_id, user_id)
        VALUES (v_conv_id, v_user_a), (v_conv_id, v_user_b);

        -- Return the created connection
        connection_id   := v_conn_id;
        user_a          := v_user_a;
        user_b          := v_user_b;
        connection_type := v_conn_type;
        conversation_id := v_conv_id;
        RETURN NEXT;
    END LOOP;

    RETURN;
END;
$$;
-- ============================================================================
-- MELSAVA Dating App — Seed Data
-- Migration: 004_seed_data.sql
-- Description: Reference data for activity categories, intentions, interests,
--              and sample experiences.
-- ============================================================================

-- ============================================================================
-- 12 Activity Categories
-- ============================================================================
INSERT INTO public.activity_categories (name, description, icon, color, display_order) VALUES
    ('Coffee & Conversation',      'Casual coffee meetups and meaningful conversations',                'coffee',       '#8B4513', 1),
    ('Board Games',                'Board game nights, card games, and puzzles',                        'games',        '#4A90D9', 2),
    ('Nature Walks',               'Hiking, park walks, and outdoor exploration',                       'hiking',       '#2E8B57', 3),
    ('Sports & Fitness',           'Sports activities, gym sessions, and fitness classes',              'fitness',      '#FF6347', 4),
    ('Photography',                'Photo walks, workshops, and creative shoots',                       'camera',       '#9B59B6', 5),
    ('Music',                      'Live music, jam sessions, and music appreciation',                  'music',        '#E74C3C', 6),
    ('Art & Creative Workshops',   'Painting, pottery, crafts, and creative expression',                'palette',      '#F39C12', 7),
    ('Food Experiences',           'Cooking classes, food tours, and tasting events',                   'restaurant',   '#E67E22', 8),
    ('Reading & Book Clubs',       'Book discussions, reading meetups, and literary events',             'book',         '#3498DB', 9),
    ('Volunteering',               'Community service, charity events, and giving back',                'heart',        '#E91E63', 10),
    ('Learning & Skill-sharing',   'Workshops, skill exchanges, and educational meetups',               'lightbulb',    '#00BCD4', 11),
    ('Cultural Activities',        'Museum visits, cultural festivals, and heritage exploration',        'museum',       '#795548', 12);

-- ============================================================================
-- 7 Intentions
-- ============================================================================
INSERT INTO public.intentions (name, description, category) VALUES
    ('Genuine friendship',     'Looking for authentic, lasting friendships',                          'friendship'),
    ('Activity partner',       'Seeking someone to share hobbies and activities with',               'friendship'),
    ('Casual dating',          'Open to casual, low-pressure dating experiences',                    'dating'),
    ('Meaningful dating',      'Looking for deeper, more intentional dating connections',            'dating'),
    ('Serious relationship',   'Seeking a committed, long-term relationship',                       'dating'),
    ('Marriage-minded',        'Looking for a life partner with marriage in mind',                   'dating'),
    ('Open to discovering',    'No fixed expectations — open to whatever develops naturally',        'friendship');

-- ============================================================================
-- 18 Interests
-- ============================================================================
INSERT INTO public.interests (name, icon, category) VALUES
    ('Travel',           'airplane',     'lifestyle'),
    ('Cooking',          'chef_hat',     'food'),
    ('Reading',          'book',         'culture'),
    ('Fitness',          'dumbbell',     'sports'),
    ('Music',            'music_note',   'arts'),
    ('Photography',      'camera',       'arts'),
    ('Hiking',           'mountain',     'outdoors'),
    ('Movies',           'film',         'entertainment'),
    ('Gaming',           'gamepad',      'entertainment'),
    ('Yoga',             'lotus',        'wellness'),
    ('Dancing',          'dance',        'arts'),
    ('Art',              'palette',      'arts'),
    ('Technology',       'laptop',       'tech'),
    ('Volunteering',     'hands',        'social'),
    ('Meditation',       'zen',          'wellness'),
    ('Languages',        'globe',        'culture'),
    ('Gardening',        'plant',        'outdoors'),
    ('Coffee',           'coffee_cup',   'food');

-- ============================================================================
-- 10 Sample Experiences
-- (host_id is NULL here — in production, these would reference real users.
--  For seed data we use a CTE to pick the first available profile, or skip
--  if no profiles exist yet.)
-- ============================================================================

-- We create a helper function for seeding to avoid FK violations when no
-- profiles exist. In production, experiences are created by real users.
DO $$
DECLARE
    v_cat_coffee   UUID;
    v_cat_board    UUID;
    v_cat_nature   UUID;
    v_cat_sports   UUID;
    v_cat_photo    UUID;
    v_cat_music    UUID;
    v_cat_art      UUID;
    v_cat_food     UUID;
    v_cat_book     UUID;
    v_cat_volunteer UUID;
BEGIN
    -- Look up category IDs
    SELECT id INTO v_cat_coffee     FROM public.activity_categories WHERE name = 'Coffee & Conversation';
    SELECT id INTO v_cat_board      FROM public.activity_categories WHERE name = 'Board Games';
    SELECT id INTO v_cat_nature     FROM public.activity_categories WHERE name = 'Nature Walks';
    SELECT id INTO v_cat_sports     FROM public.activity_categories WHERE name = 'Sports & Fitness';
    SELECT id INTO v_cat_photo      FROM public.activity_categories WHERE name = 'Photography';
    SELECT id INTO v_cat_music      FROM public.activity_categories WHERE name = 'Music';
    SELECT id INTO v_cat_art        FROM public.activity_categories WHERE name = 'Art & Creative Workshops';
    SELECT id INTO v_cat_food       FROM public.activity_categories WHERE name = 'Food Experiences';
    SELECT id INTO v_cat_book       FROM public.activity_categories WHERE name = 'Reading & Book Clubs';
    SELECT id INTO v_cat_volunteer  FROM public.activity_categories WHERE name = 'Volunteering';

    -- Insert sample experiences (draft status, no host — will need real
    -- users in production). Using a placeholder UUID that can be updated.
    -- NOTE: These will only work after at least one user has signed up.
    -- In a fresh database, these inserts are skipped gracefully.

    -- We check if any profile exists to use as host
    IF EXISTS (SELECT 1 FROM public.profiles LIMIT 1) THEN
        DECLARE
            v_host UUID;
        BEGIN
            SELECT id INTO v_host FROM public.profiles LIMIT 1;

            INSERT INTO public.experiences (title, description, category_id, host_id, city, venue_name, is_online, max_participants, status, starts_at, duration_minutes) VALUES
            (
                'Morning Coffee & Deep Conversations',
                'Start your weekend with great coffee and even better conversations. We will explore thought-provoking questions designed to help you connect authentically with others.',
                v_cat_coffee, v_host, 'San Francisco', 'Blue Bottle Coffee', FALSE, 8, 'draft',
                now() + interval '7 days', 90
            ),
            (
                'Strategy Board Game Night',
                'An evening of strategy games — from Settlers of Catan to Ticket to Ride. All experience levels welcome! Snacks provided.',
                v_cat_board, v_host, 'San Francisco', 'Game Parlour', FALSE, 12, 'draft',
                now() + interval '10 days', 180
            ),
            (
                'Golden Gate Park Sunset Walk',
                'Join us for a leisurely walk through Golden Gate Park as the sun sets. Great opportunity to unwind and meet new people in a relaxed setting.',
                v_cat_nature, v_host, 'San Francisco', 'Golden Gate Park', FALSE, 10, 'draft',
                now() + interval '5 days', 120
            ),
            (
                'Beginner-Friendly Volleyball',
                'Casual beach volleyball for all skill levels. The focus is on fun, laughter, and meeting new people — not competition!',
                v_cat_sports, v_host, 'San Francisco', 'Ocean Beach', FALSE, 16, 'draft',
                now() + interval '8 days', 120
            ),
            (
                'Street Photography Walk',
                'Explore the city through your lens. We will walk through colorful neighborhoods capturing street life and architecture. Any camera welcome, including phones!',
                v_cat_photo, v_host, 'San Francisco', 'Mission District', FALSE, 8, 'draft',
                now() + interval '12 days', 150
            ),
            (
                'Acoustic Open Mic Night',
                'Share your music or just enjoy listening! A warm, supportive environment for musicians and music lovers alike.',
                v_cat_music, v_host, 'San Francisco', 'The Attic', FALSE, 20, 'draft',
                now() + interval '14 days', 180
            ),
            (
                'Watercolor Painting for Beginners',
                'Learn the basics of watercolor painting in this hands-on workshop. All materials provided. No experience needed — just bring your curiosity!',
                v_cat_art, v_host, 'San Francisco', 'ArtHouse Studio', FALSE, 10, 'draft',
                now() + interval '9 days', 120
            ),
            (
                'Homemade Pasta Workshop',
                'Learn to make fresh pasta from scratch! We will prepare three types of pasta and enjoy them together with wine and good conversation.',
                v_cat_food, v_host, 'San Francisco', 'Kitchen on Fire', FALSE, 8, 'draft',
                now() + interval '11 days', 180
            ),
            (
                'Contemporary Fiction Book Club',
                'This month we are reading "Tomorrow, and Tomorrow, and Tomorrow" by Gabrielle Zevin. Join us for a lively discussion over coffee and pastries.',
                v_cat_book, v_host, 'San Francisco', 'City Lights Bookstore', FALSE, 12, 'draft',
                now() + interval '15 days', 120
            ),
            (
                'Beach Cleanup & Brunch',
                'Make a difference while making friends! We will spend the morning cleaning up the beach, then enjoy brunch together at a nearby café.',
                v_cat_volunteer, v_host, 'San Francisco', 'Baker Beach', FALSE, 20, 'draft',
                now() + interval '6 days', 240
            );
        END;
    ELSE
        RAISE NOTICE 'No profiles found — skipping sample experiences. They require at least one signed-up user.';
    END IF;
END;
$$;
