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
