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
7. **Atomic Server-Side Capacity & Waitlist Invariant (Phase 2)**:
   - Direct client `INSERT` and `UPDATE` on `public.experience_members` are disabled.
   - Joining and cancellation must occur through atomic stored procedures (`join_experience` and `cancel_experience_membership`) with row-level locks (`FOR UPDATE`) to guarantee zero overbooking and strictly FIFO waitlist promotion.
   - Public participant counts are exposed through an aggregate-only RPC (`get_experience_participant_counts`) without exposing membership roster PII to non-attendees.

---

## Row Level Security (RLS) Policies Matrix

| Table | SELECT Policy | INSERT Policy | UPDATE Policy | DELETE Policy |
|---|---|---|---|---|
| `profiles` | Public (non-suspended) | Auth trigger / Onboarding RPC | Own user (`id = auth.uid()`) | Admin / Auth cascade |
| `profile_private` | Own user (`user_id = auth.uid()`) | Auth trigger / Own user | Own user | Admin / Auth cascade |
| `interests` | Public (all users) | Admin only | Admin only | Admin only |
| `profile_interests` | Public | Own user | Own user | Own user |
| `intentions` | Public (all users) | Admin only | Admin only | Admin only |
| `profile_intentions`| Public | Own user | Own user | Own user |
| `activity_categories`| Public (all users) | Admin only | Admin only | Admin only |
| `experiences` | Public (published/completed) + member history | Approved host / Admin | Host (`host_id = auth.uid()`) | Host / Admin |
| `experience_members` | Co-attendees & self & host | RPC only (`join_experience`) | Host only (`mark_attended`) / RPC | Disabled |
| `post_experience_choices` | Own user (`chooser_id = auth.uid()`) | RPC only (`submit_post_experience_choices`) | Disabled | Disabled |
| `post_experience_submissions` | Own user (`user_id = auth.uid()`) | RPC only (`submit_post_experience_choices`) | Disabled | Disabled |
| `app_notifications` | Own user (`user_id = auth.uid()`) | Server / RPC only | Own user (`mark read`) | Disabled |
| `connections` | Members (`user_a = auth.uid() OR user_b = auth.uid()`) | Server function only | Disabled | Members (break connection) |
| `conversations` | Conversation members only | Server function only | Server / Members (touch updated_at) | Disabled |
| `conversation_members`| Conversation members only | Server function only | Disabled | Disabled |
| `messages` | Conversation members only | Member sender (`sender_id = auth.uid()`) | Sender (within 5m) / Member (mark read) | Sender only |
| `blocks` | Blocker (`blocker_id = auth.uid()`) | Blocker | Blocker | Blocker (unblock) |
| `reports` | Reporter (`reporter_id = auth.uid()`) | Reporter | Disabled | Disabled |
| `moderation_actions`| Moderated user (`user_id = auth.uid()`) | Admin only | Admin only | Admin only |
| `device_tokens` | Own user (`user_id = auth.uid()`) | Own user | Own user | Own user |

---

## Server-Side Database Functions (`003_functions.sql` & `006_phase2_experiences_rls_and_rpc.sql`)

### 1. `complete_profile_onboarding(...)` (Phase 2 RPC)
- `SECURITY DEFINER` atomic procedure validating `age_verified` and adult eligibility.
- Atomically saves `profiles` (with `onboarding_completed = FALSE` until done), `profile_private`, `profile_interests`, and `profile_intentions`.
- Marks `onboarding_completed = TRUE` only upon complete transactional success, preventing corrupt or half-initialized profiles.

### 2. `get_experience_participant_counts(p_experience_ids UUID[])` (Phase 2 RPC)
- `SECURITY DEFINER` aggregate function returning `(experience_id, joined_count, waitlisted_count)`.
- Eliminates client-side PII leakage by returning only integer counts, allowing non-attendees to view live capacity without reading individual participant rows.

### 3. `join_experience(p_experience_id UUID)` (Phase 2 RPC)
- `SECURITY DEFINER` atomic procedure with row-level lock (`SELECT ... FOR UPDATE` on `public.experiences`).
- Enforces:
  1. Authenticated user session.
  2. Complete adult eligibility (`age_verified = TRUE`, `onboarding_completed = TRUE`, `!is_suspended`).
  3. Valid published status (`status = 'published'`, upcoming start date).
  4. Duplicate membership prevention (`UNIQUE (experience_id, user_id)` idempotency).
  5. Capacity check (`COUNT(*) FILTER (WHERE status = 'joined') < max_participants` or unlimited capacity).
- Enrolls as `joined` if space remains; enqueues as `waitlisted` if at capacity.

### 4. `cancel_experience_membership(p_experience_id UUID)` (Phase 2 RPC)
- `SECURITY DEFINER` atomic procedure with row-level lock (`SELECT ... FOR UPDATE` on `public.experiences`).
- Cancels active caller membership (`status = 'cancelled'`, sets `cancelled_at = now()`).
- If caller was in `joined` status, automatically triggers FIFO promotion: the earliest waitlisted user (ordered by `joined_at ASC, created_at ASC, id ASC`) is promoted to `joined`.

### 5. `process_mutual_connections(p_experience_id UUID)`
- Runs as `SECURITY DEFINER` with transaction isolation.
- Finds all pairs `(A, B)` who attended the completed experience.
- Validates bidirectional choices, compatibility, and absence of blocks.
- Atomically creates `connections`, `conversations`, and `conversation_members`.

### 6. `handle_new_user()`
- Automated trigger upon `auth.users` insertion.
- Initializes placeholder `public.profiles` and `public.profile_private` rows safely.

---

## Server-Side Database Functions — Phase 3 Attendance & Mutual Choice (`009_phase3_attendance_and_mutual_choices.sql`)

### 7. `complete_experience_and_mark_attendance(p_experience_id UUID, p_attended_user_ids UUID[])`
- `SECURITY DEFINER` atomic procedure with explicit `auth.uid()` host validation.
- Validates:
  1. Caller is the verified `experiences.host_id`.
  2. Experience is in `published` status and has completed or reached start time.
  3. Only previously `joined` participants can be marked `attended`.
  4. Waitlisted, cancelled, or external users cannot be marked attended.
- Atomically marks `experiences.status = 'completed'` and updates verified participants to `attended`.

### 8. `get_host_joined_participants(p_experience_id UUID)`
- `SECURITY DEFINER` host-only review function.
- Enforces `host_id = auth.uid()`.
- Returns only joined participants for the host's attendance review sheet (display name, avatar, bio, join date).

### 9. `fetch_eligible_reconnect_attendees(p_experience_id UUID)`
- `SECURITY DEFINER` attendee discovery function.
- Enforces:
  1. Caller must have `attended` status on the completed experience.
  2. Returns only other verified `attended` co-participants.
  3. Excludes caller, blocked users in either direction, and suspended accounts.
  4. Zero private PII (email, phone, birth date) and zero private choice leakage.

### 10. `fetch_reconnect_submission_status(p_experience_id UUID)`
- `SECURITY DEFINER` gating status helper.
- Returns `is_completed`, `is_attended`, `is_submitted`, `is_host`, and `attended_count`.
- Drives clean Flutter UI state transitions (Not Eligible, Not Completed, Already Submitted, Ready).

### 11. `submit_post_experience_choices(p_experience_id UUID, p_choices JSONB)`
- `SECURITY DEFINER` atomic matching and connection engine.
- Replaces legacy 003 logic with **exact matching consent**:
  - `Friendship + Friendship` = `Friendship` connection.
  - `Activity Partner + Activity Partner` = `Activity Partner` connection.
  - `Explore Dating + Explore Dating` = `Explore Dating` connection.
  - Any mismatch (e.g. Friendship + Dating) produces **NO MATCH** (strictly zero auto-promotion to dating).
  - Any `No Connection` or one-sided selection produces **NO MATCH** with zero negative feedback.
- Atomically creates canonical `public.connections` (`user_a_id < user_b_id`), `public.conversations`, `public.conversation_members`, and in-app alerts in `public.app_notifications`.
- Idempotently records completion in `public.post_experience_submissions`.
- Returns only the authenticated caller's own new mutual connections.
