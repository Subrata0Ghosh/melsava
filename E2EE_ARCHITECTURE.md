# MELSAVA — End-to-End Encryption (E2EE) Architecture Specification

## 1. System Overview
MELSAVA implements cryptographically verified, production-grade End-to-End Encryption (E2EE) for all one-to-one messaging based on the Signal Protocol (Curve25519, X3DH, Double Ratchet, SHA-256, HMAC-SHA256, and AES-256-CBC).

The system architecture guarantees:
- **Zero Plaintext on Supabase**: Message contents never leave the user's mobile device in unencrypted form. Neither Supabase PostgreSQL tables, Realtime replication streams, nor backend push payloads possess plaintext.
- **Asynchronous Key Agreement (X3DH)**: Users can initiate an encrypted conversation with offline peers by retrieving cryptographic prekey bundles published to the Supabase directory.
- **Forward Secrecy**: Compromise of a device's current ratchet state does not reveal historical communications.
- **Post-Compromise Security (Break-in Recovery)**: The Double Ratchet continuously seeds new Diffie-Hellman entropy with each message exchange, rapidly healing the session after any potential temporary key leak.
- **Hardware-Backed Key Protection**: Identity keys and session states are securely stored in the Android Keystore and iOS Keychain via `flutter_secure_storage`.
- **Cryptographic Peer Verification**: 60-digit safety numbers and scannable QR codes allow users to physically or out-of-band verify identity keys to eliminate Man-In-The-Middle (MITM) risks.

---

## 2. Cryptographic Protocol Components

```mermaid
flowchart TD
    subgraph ClientA [Alice (Sender Device)]
        A_IK[Alice Identity Key Pair\nCurve25519]
        A_Store[SecureSignalProtocolStore\nAndroid Keystore / iOS Keychain]
        A_Ratchet[Double Ratchet Engine]
        A_Cipher[SessionCipher]
    end

    subgraph Server [Supabase Cloud Directory & Transport]
        DB_Dev[public.user_devices]
        DB_PreKeys[public.user_one_time_prekeys]
        DB_Msg[public.messages\nencrypted_payload column ONLY]
        RPC_Bundle[fetch_user_prekey_bundle()]
        RPC_Send[send_e2ee_conversation_message()]
    end

    subgraph ClientB [Bob (Recipient Device)]
        B_IK[Bob Identity Key Pair\nCurve25519]
        B_SPK[Signed PreKey\n1-year rotation]
        B_OTK[One-Time PreKeys\n50 pre-generated]
        B_Store[SecureSignalProtocolStore\nAndroid Keystore / iOS Keychain]
        B_Cipher[SessionCipher]
    end

    B_IK -->|Publish Public IK| DB_Dev
    B_SPK -->|Publish Public SPK + Sig| DB_Dev
    B_OTK -->|Upload 50 Public OTKs| DB_PreKeys

    A_Store -->|1. Request PreKey Bundle| RPC_Bundle
    RPC_Bundle -->|2. Return SPK + Single Atomic OTK| A_Store
    A_Ratchet -->|3. Compute X3DH Shared Master Key| A_Cipher
    A_Cipher -->|4. Encrypt Message Payload| RPC_Send
    RPC_Send -->|5. Insert Ciphertext Blob| DB_Msg
    DB_Msg -->|6. Supabase Realtime Broadcast| B_Cipher
    B_Cipher -->|7. Decrypt via Ratchet & Bob Private Keys| B_Store
```

### 2.1 Extended Triple Diffie-Hellman (X3DH)
When Alice initiates a session with Bob:
1. Alice requests Bob's public prekey bundle via `fetch_user_prekey_bundle(bob_id)`.
2. The Supabase RPC atomically claims and consumes one of Bob's one-time prekeys (`FOR UPDATE SKIP LOCKED`).
3. Alice verifies the signature of Bob's Signed PreKey against Bob's Identity Public Key.
4. Alice computes the four Diffie-Hellman shared secrets:
   - $DH_1 = DH(IK_A, SPK_B)$
   - $DH_2 = DH(EK_A, IK_B)$
   - $DH_3 = DH(EK_A, SPK_B)$
   - $DH_4 = DH(EK_A, OPK_B)$
5. Alice derives the master conversation key via HKDF and initializes her local Double Ratchet session.
6. Alice sends her initial message as a `PreKeySignalMessage` containing her ephemeral public key $EK_A$ and identity key $IK_A$.
7. Bob computes the identical $DH_1 \dots DH_4$ using his private keys, deletes the consumed one-time prekey from his local storage, and initializes his Double Ratchet receiving state.

### 2.2 The Double Ratchet
After the initial handshake:
- Each message exchanges a new Diffie-Hellman ratchet key pair.
- Symmetric KDF ratchets advance step-by-step for each message sent and received.
- Each message key is used exactly once and immediately destroyed.

---

## 3. Storage & Key Security Model

| Key Artifact | Generation | Storage Location | Protection Mechanism |
| :--- | :--- | :--- | :--- |
| **Identity Key Pair ($IK$)** | On-device at first login | `flutter_secure_storage` | Android Keystore / iOS Keychain (Hardware TEE / Secure Enclave) |
| **Signed PreKey Pair ($SPK$)** | On-device, rotated periodically | `flutter_secure_storage` | Hardware-backed keystore |
| **One-Time PreKey Pairs ($OPK$)** | On-device in batches of 50 | `flutter_secure_storage` | Hardware-backed keystore; deleted immediately upon consumption |
| **Session States & Ratchet Keys** | In-memory during app runtime | `flutter_secure_storage` | AES encrypted payload in system secure storage |
| **Public Keys & PreKey Bundles** | Exported Base64 public keys only | Supabase `user_devices` & `user_one_time_prekeys` | Protected by Postgres Row Level Security (RLS) |

---

## 4. Threat Model & Countermeasures

| Threat Vector | Attack Scenario | MELSAVA Countermeasure |
| :--- | :--- | :--- |
| **Compromised Server / Malicious Admin** | Attacker accesses Supabase database directly or intercepts Postgres network traffic. | Messages stored and transferred only as Base64 ciphertext. Plaintext never exists on server. |
| **Man-In-The-Middle (MITM)** | Malicious network actor substitutes Bob's identity key with an imposter key. | 60-digit Safety Number and QR fingerprint comparison detects any identity key mismatch immediately. |
| **Replay Attack** | Interceptor re-transmits an existing ciphertext to trigger duplicate messages or disrupt ratchet state. | Double Ratchet maintains incoming message counters and rejects duplicates with `DuplicateMessageException`. Supabase enforces idempotency with unique `client_request_id`. |
| **Message Tampering / Flipping** | Attacker flips bits in the ciphertext during transit. | Authenticated encryption (HMAC-SHA256) rejects modified ciphertexts; decryption throws authentication failure. |
| **Device Theft (Historical Data)** | Attacker gains access to a stolen device. | Double Ratchet forward secrecy ensures historical message keys already deleted cannot be derived from current state. |
| **Eavesdropper Interception** | Third party (Eve) captures message broadcasts. | Lacking Bob's private identity and ratchet keys, decryption fails with crypto exceptions. |

---

## 5. E2EE-Aware Moderation & Safety Number Verification

1. **Safety Number Generation**: Computed using Signal's standard `NumericFingerprintGenerator` (5200 iterations). Formatted as 12 blocks of 5 digits (60 digits total). Scannable QR code encoded as `melsava-e2ee://verify?u=<user_id>&fp=<fingerprint_hex>`.
2. **Key Change Alerting**: If a user re-installs the app or switches devices, `SecureSignalProtocolStore` detects a new identity public key for that user address and surfaces a security banner:
   > ⚠️ *"[User]'s security number has changed. They may have reinstalled MELSAVA or switched devices."*
3. **User Reporting & Abuse Handling**:
   - The report dialog explicitly informs reporting users:
     > *"🔒 End-to-End Encrypted Chat: Because this conversation is end-to-end encrypted, MELSAVA moderators cannot read message histories on the server."*
   - Users may attach reported message excerpts directly from their decrypted local view with their cryptographic signature to establish authentic abuse evidence without breaking system-wide encryption.
