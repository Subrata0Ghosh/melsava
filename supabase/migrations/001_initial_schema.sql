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
