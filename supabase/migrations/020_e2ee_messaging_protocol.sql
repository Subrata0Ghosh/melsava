-- ============================================================================
-- Migration 020: Production-Ready End-to-End Encrypted (E2EE) Messaging
--
-- Signal Protocol key directory, one-time prekeys, and encrypted messaging.
-- Ensures zero plaintext messages reach the database.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Table: user_devices (Public identity & signed prekey directory)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_devices (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    device_id               INT NOT NULL DEFAULT 1,
    registration_id         INT NOT NULL,
    identity_key            TEXT NOT NULL,
    signed_prekey_id        INT NOT NULL,
    signed_prekey           TEXT NOT NULL,
    signed_prekey_signature TEXT NOT NULL,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_device UNIQUE (user_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON public.user_devices(user_id);

-- ----------------------------------------------------------------------------
-- 2. Table: user_one_time_prekeys (One-time prekeys for asynchronous X3DH)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_one_time_prekeys (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    device_id   INT NOT NULL DEFAULT 1,
    key_id      INT NOT NULL,
    public_key  TEXT NOT NULL,
    is_consumed BOOLEAN NOT NULL DEFAULT FALSE,
    consumed_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_device_otk UNIQUE (user_id, device_id, key_id)
);

CREATE INDEX IF NOT EXISTS idx_user_otk_lookup 
ON public.user_one_time_prekeys(user_id, device_id, is_consumed);

-- ----------------------------------------------------------------------------
-- 3. Extend messages table with E2EE metadata
-- ----------------------------------------------------------------------------
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS is_encrypted BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS encrypted_payload TEXT;

ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS sender_device_id INT DEFAULT 1;

ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS recipient_device_id INT DEFAULT 1;

ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS recipient_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS client_request_id TEXT;

-- Index for idempotent message delivery
CREATE UNIQUE INDEX IF NOT EXISTS idx_messages_idempotent
ON public.messages (conversation_id, client_request_id)
WHERE client_request_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 4. Enable RLS on newly created tables
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_one_time_prekeys ENABLE ROW LEVEL SECURITY;

-- user_devices RLS
DROP POLICY IF EXISTS "Authenticated users can view device public keys" ON public.user_devices;
CREATE POLICY "Authenticated users can view device public keys"
ON public.user_devices FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Users can insert their own device keys" ON public.user_devices;
CREATE POLICY "Users can insert their own device keys"
ON public.user_devices FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own device keys" ON public.user_devices;
CREATE POLICY "Users can update their own device keys"
ON public.user_devices FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own device keys" ON public.user_devices;
CREATE POLICY "Users can delete their own device keys"
ON public.user_devices FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- user_one_time_prekeys RLS
DROP POLICY IF EXISTS "Users can manage their own one-time prekeys" ON public.user_one_time_prekeys;
CREATE POLICY "Users can manage their own one-time prekeys"
ON public.user_one_time_prekeys FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 5. RPC: register_device_keys
-- Atomically registers public identity, signed prekey, and batch of one-time prekeys
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.register_device_keys(
    p_device_id               INT,
    p_registration_id         INT,
    p_identity_key            TEXT,
    p_signed_prekey_id        INT,
    p_signed_prekey           TEXT,
    p_signed_prekey_signature TEXT,
    p_one_time_prekeys        JSONB DEFAULT '[]'::JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_otk JSONB;
    v_count INT := 0;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_identity_key IS NULL OR p_signed_prekey IS NULL OR p_signed_prekey_signature IS NULL THEN
        RAISE EXCEPTION 'Missing public key parameters';
    END IF;

    -- Upsert user device record
    INSERT INTO public.user_devices (
        user_id,
        device_id,
        registration_id,
        identity_key,
        signed_prekey_id,
        signed_prekey,
        signed_prekey_signature,
        updated_at
    ) VALUES (
        v_uid,
        COALESCE(p_device_id, 1),
        p_registration_id,
        p_identity_key,
        p_signed_prekey_id,
        p_signed_prekey,
        p_signed_prekey_signature,
        now()
    )
    ON CONFLICT (user_id, device_id)
    DO UPDATE SET
        registration_id         = EXCLUDED.registration_id,
        identity_key            = EXCLUDED.identity_key,
        signed_prekey_id        = EXCLUDED.signed_prekey_id,
        signed_prekey           = EXCLUDED.signed_prekey,
        signed_prekey_signature = EXCLUDED.signed_prekey_signature,
        updated_at              = now();

    -- Insert one-time prekeys
    IF p_one_time_prekeys IS NOT NULL AND jsonb_array_length(p_one_time_prekeys) > 0 THEN
        FOR v_otk IN SELECT * FROM jsonb_array_elements(p_one_time_prekeys)
        LOOP
            INSERT INTO public.user_one_time_prekeys (
                user_id,
                device_id,
                key_id,
                public_key,
                is_consumed
            ) VALUES (
                v_uid,
                COALESCE(p_device_id, 1),
                (v_otk->>'key_id')::INT,
                v_otk->>'public_key',
                FALSE
            )
            ON CONFLICT (user_id, device_id, key_id)
            DO UPDATE SET
                public_key  = EXCLUDED.public_key,
                is_consumed = FALSE,
                consumed_at = NULL;

            v_count := v_count + 1;
        END LOOP;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', v_uid,
        'device_id', COALESCE(p_device_id, 1),
        'prekeys_registered', v_count
    );
END;
$$;

REVOKE ALL ON FUNCTION public.register_device_keys(INT, INT, TEXT, INT, TEXT, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_device_keys(INT, INT, TEXT, INT, TEXT, TEXT, JSONB) TO authenticated;

-- ----------------------------------------------------------------------------
-- 6. RPC: fetch_user_prekey_bundle
-- Atomically fetches public key bundle and consumes one unconsumed one-time prekey
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fetch_user_prekey_bundle(
    p_user_id   UUID,
    p_device_id INT DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid              UUID := auth.uid();
    v_device           RECORD;
    v_otk_id           INT := NULL;
    v_otk_pub          TEXT := NULL;
    v_otk_record_id    UUID := NULL;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Lookup device
    SELECT * INTO v_device
    FROM public.user_devices
    WHERE user_id = p_user_id
      AND device_id = COALESCE(p_device_id, 1);

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Device keys not registered for user.'
        );
    END IF;

    -- Atomically select and consume 1 one-time prekey with row lock
    SELECT id, key_id, public_key INTO v_otk_record_id, v_otk_id, v_otk_pub
    FROM public.user_one_time_prekeys
    WHERE user_id = p_user_id
      AND device_id = COALESCE(p_device_id, 1)
      AND is_consumed = FALSE
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF v_otk_record_id IS NOT NULL THEN
        UPDATE public.user_one_time_prekeys
        SET is_consumed = TRUE,
            consumed_at = now()
        WHERE id = v_otk_record_id;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', v_device.user_id,
        'device_id', v_device.device_id,
        'registration_id', v_device.registration_id,
        'identity_key', v_device.identity_key,
        'signed_prekey_id', v_device.signed_prekey_id,
        'signed_prekey', v_device.signed_prekey,
        'signed_prekey_signature', v_device.signed_prekey_signature,
        'one_time_prekey_id', v_otk_id,
        'one_time_prekey', v_otk_pub
    );
END;
$$;

REVOKE ALL ON FUNCTION public.fetch_user_prekey_bundle(UUID, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fetch_user_prekey_bundle(UUID, INT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 7. RPC: replenish_one_time_prekeys
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.replenish_one_time_prekeys(
    p_device_id        INT,
    p_one_time_prekeys JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid   UUID := auth.uid();
    v_otk   JSONB;
    v_count INT := 0;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_one_time_prekeys IS NOT NULL AND jsonb_array_length(p_one_time_prekeys) > 0 THEN
        FOR v_otk IN SELECT * FROM jsonb_array_elements(p_one_time_prekeys)
        LOOP
            INSERT INTO public.user_one_time_prekeys (
                user_id,
                device_id,
                key_id,
                public_key,
                is_consumed
            ) VALUES (
                v_uid,
                COALESCE(p_device_id, 1),
                (v_otk->>'key_id')::INT,
                v_otk->>'public_key',
                FALSE
            )
            ON CONFLICT (user_id, device_id, key_id)
            DO UPDATE SET
                public_key  = EXCLUDED.public_key,
                is_consumed = FALSE,
                consumed_at = NULL;

            v_count := v_count + 1;
        END LOOP;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'replenished_count', v_count
    );
END;
$$;

REVOKE ALL ON FUNCTION public.replenish_one_time_prekeys(INT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.replenish_one_time_prekeys(INT, JSONB) TO authenticated;

-- ----------------------------------------------------------------------------
-- 8. RPC: get_unconsumed_prekey_count
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_unconsumed_prekey_count(
    p_device_id INT DEFAULT 1
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid   UUID := auth.uid();
    v_count INT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT COUNT(*)::INT INTO v_count
    FROM public.user_one_time_prekeys
    WHERE user_id = v_uid
      AND device_id = COALESCE(p_device_id, 1)
      AND is_consumed = FALSE;

    RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.get_unconsumed_prekey_count(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_unconsumed_prekey_count(INT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 9. RPC: send_e2ee_conversation_message
-- Strictly requires encrypted_payload. Stores zero plaintext on Supabase.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.send_e2ee_conversation_message(
    p_conversation_id    UUID,
    p_recipient_id       UUID,
    p_encrypted_payload  TEXT,
    p_sender_device_id   INT DEFAULT 1,
    p_recipient_device_id INT DEFAULT 1,
    p_client_request_id  TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid       UUID := auth.uid();
    v_msg_id    UUID;
    v_now       TIMESTAMPTZ := now();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_encrypted_payload IS NULL OR TRIM(p_encrypted_payload) = '' THEN
        RAISE EXCEPTION 'Encrypted payload cannot be empty.';
    END IF;

    -- Verify caller access via security helper (validates membership, connection, blocks, suspension)
    IF NOT public.can_access_conversation(p_conversation_id) THEN
        RAISE EXCEPTION 'Unauthorized conversation member';
    END IF;

    -- Idempotency check: if client_request_id exists, return existing message
    IF p_client_request_id IS NOT NULL THEN
        SELECT id INTO v_msg_id
        FROM public.messages
        WHERE conversation_id = p_conversation_id
          AND client_request_id = p_client_request_id;

        IF v_msg_id IS NOT NULL THEN
            RETURN jsonb_build_object(
                'success', TRUE,
                'message_id', v_msg_id,
                'conversation_id', p_conversation_id,
                'sender_id', v_uid,
                'is_encrypted', TRUE,
                'is_duplicate', TRUE
            );
        END IF;
    END IF;

    -- Insert E2EE message. Plaintext content is set to sentinel value '[Encrypted Message]'
    INSERT INTO public.messages (
        conversation_id,
        sender_id,
        content,
        is_read,
        created_at,
        is_encrypted,
        encrypted_payload,
        sender_device_id,
        recipient_device_id,
        recipient_id,
        client_request_id
    ) VALUES (
        p_conversation_id,
        v_uid,
        '[Encrypted Message]',
        FALSE,
        v_now,
        TRUE,
        p_encrypted_payload,
        COALESCE(p_sender_device_id, 1),
        COALESCE(p_recipient_device_id, 1),
        p_recipient_id,
        p_client_request_id
    )
    RETURNING id INTO v_msg_id;

    -- Update conversation updated_at
    UPDATE public.conversations
       SET updated_at = v_now
     WHERE id = p_conversation_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'message_id', v_msg_id,
        'conversation_id', p_conversation_id,
        'sender_id', v_uid,
        'recipient_id', p_recipient_id,
        'is_encrypted', TRUE,
        'created_at', v_now
    );
END;
$$;

REVOKE ALL ON FUNCTION public.send_e2ee_conversation_message(UUID, UUID, TEXT, INT, INT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_e2ee_conversation_message(UUID, UUID, TEXT, INT, INT, TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 10. Update get_conversation_messages to return E2EE fields
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_conversation_messages(UUID, INT, TIMESTAMPTZ);

CREATE OR REPLACE FUNCTION public.get_conversation_messages(
    p_conversation_id UUID,
    p_limit           INT DEFAULT 50,
    p_before          TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    message_id          UUID,
    sender_id           UUID,
    content             TEXT,
    is_read             BOOLEAN,
    created_at          TIMESTAMPTZ,
    is_me               BOOLEAN,
    is_encrypted        BOOLEAN,
    encrypted_payload   TEXT,
    sender_device_id    INT,
    recipient_device_id INT,
    recipient_id        UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid        UUID := auth.uid();
    v_eff_limit  INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 100);
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT public.can_access_conversation(p_conversation_id) THEN
        RAISE EXCEPTION 'Unauthorized conversation access';
    END IF;

    RETURN QUERY
    WITH msg_page AS (
        SELECT
            m.id AS message_id,
            m.sender_id,
            m.content,
            m.is_read,
            m.created_at,
            (m.sender_id = v_uid) AS is_me,
            COALESCE(m.is_encrypted, FALSE) AS is_encrypted,
            m.encrypted_payload,
            m.sender_device_id,
            m.recipient_device_id,
            m.recipient_id
        FROM public.messages m
        WHERE m.conversation_id = p_conversation_id
          AND (p_before IS NULL OR m.created_at < p_before)
        ORDER BY m.created_at DESC
        LIMIT v_eff_limit
    )
    SELECT * FROM msg_page
    ORDER BY created_at ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_conversation_messages(UUID, INT, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_conversation_messages(UUID, INT, TIMESTAMPTZ) TO authenticated;
