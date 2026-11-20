-- ============================================================================
-- MELSAVA - Migration 015: Fix Experience Circle Participants RPC
-- ============================================================================
-- Description:
--   Resolves PostgreSQL error 42702 (column reference "user_id" is ambiguous)
--   in `get_experience_circle_participants` by qualifying `experience_members.user_id`
--   and `experience_members.experience_id` against the function's OUT parameters.
-- ============================================================================

DROP FUNCTION IF EXISTS public.get_experience_circle_participants(UUID);

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

    SELECT e.host_id INTO v_host_id
    FROM public.experiences e
    WHERE e.id = p_experience_id;

    IF v_host_id IS NULL THEN
        RAISE EXCEPTION 'Experience not found';
    END IF;

    -- Caller must be host or active joined member
    SELECT EXISTS (
        SELECT 1 FROM public.experience_members em
        WHERE em.experience_id = p_experience_id
          AND em.user_id = v_caller_id
          AND em.status IN ('joined', 'attended')
    ) INTO v_is_member;

    IF v_caller_id != v_host_id AND NOT v_is_member THEN
        RAISE EXCEPTION 'Only active joined participants and the host can view the meetup circle';
    END IF;

    -- Return Host first
    RETURN QUERY
    SELECT 
        p.id AS user_id,
        COALESCE(p.display_name, 'Host')::TEXT AS display_name,
        COALESCE(p.avatar_url, '')::TEXT AS avatar_url,
        COALESCE(p.bio, '')::TEXT AS bio,
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
        COALESCE(p.display_name, 'Participant')::TEXT AS display_name,
        COALESCE(p.avatar_url, '')::TEXT AS avatar_url,
        COALESCE(p.bio, '')::TEXT AS bio,
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
