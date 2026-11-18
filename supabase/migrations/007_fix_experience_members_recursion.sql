-- ============================================================================
-- MELSAVA — Fix Infinite Recursion in experience_members & experiences RLS
-- Migration: 007_fix_experience_members_recursion.sql
-- ============================================================================

-- 1. Helper function: check if caller is host (SECURITY DEFINER breaks RLS recursion)
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

-- 2. Helper function: check if caller is member (SECURITY DEFINER breaks RLS recursion)
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

-- 3. Replace recursive select policy on experience_members
DROP POLICY IF EXISTS "experience_members_select" ON public.experience_members;

CREATE POLICY "experience_members_select"
    ON public.experience_members FOR SELECT
    TO authenticated
    USING (
        user_id = auth.uid()
        OR public.is_experience_host(experience_id)
    );

-- 4. Replace policy on experiences to use non-recursive helper
DROP POLICY IF EXISTS "experiences_select_member_history" ON public.experiences;

CREATE POLICY "experiences_select_member_history"
    ON public.experiences FOR SELECT
    TO authenticated
    USING (
        public.is_experience_member(id)
    );
