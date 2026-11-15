# MELSAVA Security and Row Level Security (RLS) Architecture

## Security Philosophy
MELSAVA treats user privacy, safety, and mutual consent as paramount. Client applications (such as the Flutter mobile app) are untrusted clients. The application enforces all privacy rules, mutual-consent logic, and access constraints at the PostgreSQL database level using Row Level Security (RLS) and server-side stored procedures.

---

## Threat Model & Core Invariants

1. **Unilateral Consent Prevention**:
   - A user must NEVER be able to unilaterally connect with another user.
   - Connections can ONLY be created by the atomic server-side function `process_mutual_connections()`, which requires compatible, private, bidirectional choices.
2. **Private Choice Confidentiality**:
   - Post-experience selections (`post_experience_choices`) are strictly confidential.
   - User A can NEVER inspect or query User B's choice until and unless a mutual connection is recorded.
   - No negative/rejection feedback is ever emitted.
3. **Data Segregation (Public vs. Private)**:
   - Public discovery queries access `profiles` (display name, avatar, bio, city, verified badge).
   - Sensitive PII (email, birth date, verification logs) is sequestered in `profile_private`.
   - Other users have ZERO read or write access to another user's `profile_private` row.
4. **Chat Isolation**:
   - A user cannot read or insert messages into a conversation unless their user ID is registered in `conversation_members` for that conversation.
5. **Enforced Blocking & Moderation**:
   - When User A blocks User B, neither user can view the other in discovery, join the same micro-capacity experiences, or message each other.
   - Suspended accounts are immediately blocked from mutating data or initiating connections.
6. **No Client Service Keys**:
   - The Flutter mobile client bundles ONLY the Supabase `ANON` public key.
   - The `SERVICE_ROLE` key is never compiled into client binaries or accessible to end users.

---

## Row Level Security (RLS) Policies Matrix

| Table | SELECT Policy | INSERT Policy | UPDATE Policy | DELETE Policy |
|---|---|---|---|---|
| `profiles` | Public (non-suspended) | Auth trigger only | Own user (`id = auth.uid()`) | Admin / Auth cascade |
| `profile_private` | Own user (`user_id = auth.uid()`) | Auth trigger / Own user | Own user | Admin / Auth cascade |
| `interests` | Public (all users) | Admin only | Admin only | Admin only |
| `profile_interests` | Public | Own user | Own user | Own user |
| `intentions` | Public (all users) | Admin only | Admin only | Admin only |
| `profile_intentions`| Public | Own user | Own user | Own user |
| `activity_categories`| Public (all users) | Admin only | Admin only | Admin only |
| `experiences` | Public (published/completed) | Approved host / Admin | Host (`host_id = auth.uid()`) | Host / Admin |
| `experience_members` | Co-attendees & self | Own user (if spots open) | Own user (status = 'cancelled') | Disabled |
| `post_experience_choices` | Own user (`chooser_id = auth.uid()`) | Own user | Own user | Disabled |
| `connections` | Members (`user_a = auth.uid() OR user_b = auth.uid()`) | Server function only | Disabled | Members (break connection) |
| `conversations` | Conversation members only | Server function only | Server / Members (touch updated_at) | Disabled |
| `conversation_members`| Conversation members only | Server function only | Disabled | Disabled |
| `messages` | Conversation members only | Member sender (`sender_id = auth.uid()`) | Sender (within 5m) / Member (mark read) | Sender only |
| `blocks` | Blocker (`blocker_id = auth.uid()`) | Blocker | Blocker | Blocker (unblock) |
| `reports` | Reporter (`reporter_id = auth.uid()`) | Reporter | Disabled | Disabled |
| `moderation_actions`| Moderated user (`user_id = auth.uid()`) | Admin only | Admin only | Admin only |
| `device_tokens` | Own user (`user_id = auth.uid()`) | Own user | Own user | Own user |

---

## Server-Side Database Functions (`003_functions.sql`)

### 1. `process_mutual_connections(p_experience_id UUID)`
- Runs as `SECURITY DEFINER` with transaction isolation.
- Finds all pairs `(A, B)` who attended the completed experience.
- Validates that:
  - `A` chose `B` with an intention != `'no_connection'`.
  - `B` chose `A` with an intention != `'no_connection'`.
  - Intention types are compatible (Friendship with Friendship/Activity Partner, or Dating with Dating).
  - No active block exists between `A` and `B`.
- Atomically inserts:
  1. Record in `connections`.
  2. Record in `conversations`.
  3. Records in `conversation_members` for both parties.
- Returns list of newly established connection records.

### 2. `check_experience_capacity(p_experience_id UUID)`
- Prevents overbooking race conditions by computing `COUNT(*) FILTER (WHERE status = 'joined') < max_participants`.

### 3. `handle_new_user()`
- Automated trigger upon `auth.users` insertion.
- Initializes placeholder `public.profiles` and `public.profile_private` rows safely.
