# MELSAVA — E2EE Messaging Production Deployment Guide

## 1. Migration 020 Deployment Overview
The cryptographic schema extensions and directory RPCs are defined in:
`supabase/migrations/020_e2ee_messaging_protocol.sql`

This migration was applied to the production Supabase PostgreSQL instance:
- **Project Ref**: `luxxwitcptqesmnqruld`
- **Tables Deployed**:
  - `public.user_devices`: Stores public identity keys, signed prekeys, and device registration IDs.
  - `public.user_one_time_prekeys`: Stores pool of public one-time prekeys for asynchronous X3DH handshake.
- **Messages Extensions**:
  - `is_encrypted` (boolean)
  - `encrypted_payload` (text, Base64 JSON envelope)
  - `sender_device_id` (integer)
  - `recipient_device_id` (integer)
  - `recipient_id` (UUID references auth.users)
  - `client_request_id` (text, idempotency guard)
- **Functions & RPCs**:
  - `register_device_keys(device_id, registration_id, identity_public_key, signed_prekey_id, signed_prekey_public, signed_prekey_signature, one_time_prekeys)`
  - `fetch_user_prekey_bundle(user_id, device_id)`
  - `replenish_one_time_prekeys(device_id, prekeys)`
  - `get_unconsumed_prekey_count(device_id)`
  - `send_e2ee_conversation_message(conversation_id, recipient_id, encrypted_payload, sender_device_id, recipient_device_id, client_request_id)`
  - Updated `get_conversation_messages(conversation_id, limit, before_cursor)`

---

## 2. Row Level Security (RLS) Policies

1. **`user_devices`**:
   - `SELECT`: Any authenticated user can read public device keys to initiate a session.
   - `INSERT / UPDATE`: Users can only register or update keys for their own `auth.uid()`.
   - `DELETE`: Users can only revoke their own devices.

2. **`user_one_time_prekeys`**:
   - `INSERT`: Users can only upload prekeys for their own `auth.uid()`.
   - `SELECT`: Consumed internally by `fetch_user_prekey_bundle` using `SECURITY DEFINER` with `FOR UPDATE SKIP LOCKED`. Direct queries restricted.

3. **`messages`**:
   - `INSERT`: Authenticated participants of the conversation only.
   - `SELECT`: Only members of the conversation can retrieve message payloads.

---

## 3. Client Environment Prerequisites

1. **Flutter Dependencies**:
   - `libsignal_protocol_dart: ^0.8.2` (Pure Dart Signal Protocol implementation)
   - `flutter_secure_storage: ^11.2.0` (Hardware-backed Keystore/Keychain)
   - `qr_flutter: ^4.1.0` (High-fidelity QR code rendering for safety numbers)

2. **Android Keystore Setup**:
   - Minimum SDK: API 21 (Android 5.0 Lollipop).
   - Target SDK: API 34+.
   - Verified on Android 16 (`emulator-5554`).
   - Keystore keys are stored inside hardware-backed TEE / StrongBox where available.

3. **iOS Keychain Setup**:
   - `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` configured to prevent migration to unmanaged backup stores.

---

## 4. Maintenance & Operations

### PreKey Exhaustion Monitoring
Supabase database admins can monitor global one-time prekey consumption with the following query:
```sql
SELECT 
    user_id, 
    COUNT(*) FILTER (WHERE is_consumed = FALSE) AS available_otks,
    COUNT(*) FILTER (WHERE is_consumed = TRUE) AS consumed_otks
FROM public.user_one_time_prekeys
GROUP BY user_id
HAVING COUNT(*) FILTER (WHERE is_consumed = FALSE) < 15;
```

### Serverless Push Notification Privacy
For E2EE chats, background push notifications must NEVER include message plaintext.
The payload format dispatched to FCM/APNS:
```json
{
  "title": "MELSAVA",
  "body": "New encrypted message received",
  "data": {
    "type": "e2ee_chat_message",
    "conversation_id": "...",
    "sender_id": "..."
  }
}
```
The client app wakes up in the background or upon open, loads the encrypted payload from Supabase, decrypts it locally with its private ratchet key, and displays the user notification.
