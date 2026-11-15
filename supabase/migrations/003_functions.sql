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
