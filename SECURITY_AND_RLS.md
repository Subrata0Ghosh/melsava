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

### 12. `get_experience_circle_participants(p_experience_id UUID)`
- `SECURITY DEFINER` function with `search_path = public`.
- Validates caller is either the host or a confirmed joined/attended participant.
- Excludes blocked and suspended accounts.
- Zero PII: returns only approved public profile information (name, avatar, bio, role).

### 13. Security Deprecation: `process_mutual_connections(p_experience_id UUID)`
- The legacy matching function from migration 003 has been superseded and deprecated.
- All client permissions (`PUBLIC`, `anon`, `authenticated`) have been revoked.
- Function body raises an explicit exception if invoked, preventing any client from bypassing attended verification or intention matching rules.

---

## Phase 3 Hardening & Security Hardening (`012_phase3_hardening.sql`)

### 14. Hardened `complete_experience_and_mark_attendance(p_experience_id UUID, p_attended_user_ids UUID[])`
- Row lock (`FOR UPDATE`) on parent experience to serialize concurrent completion calls.
- Scheduled completion verification: rejects execution before scheduled end time (`ends_at` or `starts_at + duration_minutes`). Raises clear exception if duration information is missing.
- Rejects draft and cancelled experiences.
- Rejects duplicate attendee user IDs in the submission array.
- Rejects user IDs that do not belong to confirmed joined memberships.
- Idempotent safe handling: if experience is already completed, returns the current attended count without modifying finalized records.

### 15. Hardened `submit_post_experience_choices(p_experience_id UUID, p_choices JSONB)`
- Row lock (`FOR UPDATE`) on parent experience to serialize concurrent reciprocal submissions and prevent missed mutual connections.
- Validates all submitted participant IDs: rejects self-selection, non-attendees, and duplicate entries.
- Rejects invalid choice types.
- Enforces exact matching compatibility (Friendship=Friendship, Activity=Activity, Dating=Dating; mismatched=no connection; no upgrades).
- Safe retry idempotency: prevents duplicate connections, duplicate conversations, or duplicate notifications.

---

## Server-Side Database Functions & RLS — Phase 4 Messaging & Realtime (`013_phase4_connections_and_realtime.sql`)

### 16. `can_access_conversation(p_conversation_id UUID)`
- Central security predicate (`SECURITY DEFINER`) for conversation and message RLS.
- Enforces:
  1. Caller is an active member in `public.conversation_members`.
  2. Associated mutual connection exists in `public.connections`.
  3. Neither participant has blocked the other in `public.blocks`.
  4. Neither participant has a suspended or banned account in `public.moderation_actions`.
  5. The caller is an authenticated user (`auth.uid()`).

### 17. Tightened RLS Policies for Messaging
- **`conversations`**:
  - `SELECT`: Member with valid access (`can_access_conversation(id)`).
  - Direct `INSERT` / `UPDATE` / `DELETE`: Denied for client roles; managed strictly via security definer RPCs.
- **`conversation_members`**:
  - `SELECT`: Accessible only to members of that conversation where `can_access_conversation(conversation_id)`.
  - Direct client mutations denied.
- **`messages`**:
  - `SELECT`: Accessible only to verified members where `can_access_conversation(conversation_id)`.
  - Direct `INSERT` / `UPDATE` / `DELETE`: Dropped or restricted to RPCs. `send_conversation_message` sets sender ID from `auth.uid()`, enforces 1,000 char maximum, and rejects empty messages.

### 18. Phase 4 Secure RPCs
- **`get_user_connections()`**: Authenticated mutual connections only. Enforces mutual consent, blocks exclusion, and sanitizes public profile data.
- **`get_user_inbox_threads()`**: Authenticated member threads only. Aggregates genuine unread counts (`is_read = FALSE` for peer messages).
- **`get_conversation_messages(p_conversation_id, p_limit, p_before)`**: Chronological paginated history for authorized conversation members.
- **`get_or_create_conversation_for_connection(p_connection_id)`**: Safe resolver/creator ensuring exactly 2 members.
- **`send_conversation_message(p_conversation_id, p_content)`**: Server-validated plain text messaging with character limit (1,000 chars) and server-stamped timestamp.
- **`mark_conversation_read(p_conversation_id)`**: Atomic read receipt updater for incoming unread messages.

---

## Phase 5 Security Hardening, Moderation & Safety Architecture (`014_phase5_safety_and_profile.sql`)

### 19. Phase 4 Security Preflight (Migration 014 Hardening)
- **Direct Messages INSERT Policy Dropped**: Direct client insertion on `public.messages` is completely disabled. All message delivery must pass through `send_conversation_message` RPC which validates conversation membership, active mutual connection, absence of blocks, account non-suspension, trims whitespace, and stamps `sender_id = auth.uid()`.
- **Direct Messages UPDATE Policy Dropped**: Direct client updates on `public.messages` are completely disabled. Recipients cannot alter content, sender ID, or timestamps. Read receipt status is modified exclusively by `mark_conversation_read` RPC.
- **Revocation of Direct Privileges**: `REVOKE INSERT, UPDATE ON public.messages FROM anon, authenticated;` is enforced at the database privilege level.
- **Strengthened `can_access_conversation(UUID)`**: Explicitly verifies both caller and recipient accounts are active and un-suspended, confirms membership, and checks blocks in both directions (`blocker_id = A AND blocked_id = B OR blocker_id = B AND blocked_id = A`).

### 20. Atomic Profile Update Protection (`update_user_profile`)
- Replaces partial client-side table writes with a single atomic `SECURITY DEFINER` RPC.
- Strictly validates display name length (2–50 characters) and trims input.
- Updates `profiles`, `profile_interests`, `profile_intentions`, and `profile_private` in a single transaction.
- **Security Boundary**: Directly prevents client modification of protected system fields (`id`, `is_verified`, `is_suspended`, `date_of_birth`).

### 21. Real Block & Unblock System
- `block_user(p_blocked_id UUID)`: Enforces `p_blocked_id != auth.uid()` (rejects self-blocking) and handles idempotency with `ON CONFLICT DO NOTHING`.
- `unblock_user(p_blocked_id UUID)`: Removes block relation cleanly.
- `get_blocked_users()`: Returns authentic blocked accounts for Settings management, joining `public.profiles` safely.

### 22. Real Reporting & Moderation Infrastructure
- `submit_user_report(UUID, TEXT, TEXT, TEXT, UUID)`:
  - Validates 9 canonical categories: Harassment or unwanted contact, Impersonation or fake profile, Underage user concern, Commercial solicitation or spam, Inappropriate behavior at meetup, No-show without notice, Hate speech or discrimination, Safety or privacy concern, Other.
  - Enforces 500-character max on additional context.
  - Rejects self-reporting and verifies reported target exists in `public.profiles`.
  - Reporter identity is strictly confidential; reports are hidden from the reported user.
- **Moderation Access Control**:
  - `public.moderators` table protected by RLS.
  - `is_moderator()` security helper evaluates JWT claims (`role IN ('admin', 'moderator')`) or membership in `public.moderators`.
  - `get_moderation_reports(p_status)`: Accessible only to authorized moderators.
  - `resolve_moderation_report(p_report_id, p_new_status)`: Updates status (`reviewed`, `resolved`, `dismissed`).
  - `apply_moderation_action(...)`: Logs administrative action in `moderation_actions` and instantly flips `is_suspended = TRUE` on `public.profiles` for suspensions and bans.

### 23. Permanent Account Deletion Safeguards (`delete-account` Edge Function)
- Dedicated `delete-account` Supabase Edge Function is the SINGLE permanent deletion mechanism.
- Validates Bearer JWT via `auth.getUser()`.
- Enforces recent re-authentication (<15 minutes) server-side from JWT claims/last_sign_in_at to prevent unauthorized or stale token deletions.
- Requires typed payload confirmation `{"confirmation": "DELETE"}`.
- Cleans up user avatars in Supabase Storage (`avatars/${userId}`).
- Deletes user via Supabase Auth Admin API (`adminClient.auth.admin.deleteUser(userId)`), which cascades across all foreign keys on `profiles.id` and child tables.
- Legacy SQL RPC `delete_user_account_permanent` has been completely dropped and revoked.
- Client-side fallback to direct table deletion is strictly removed.

### 24. Privacy Controls & Settings Persistence (`017_phase5_security_and_integrity_hardening.sql`)
- Private user settings (`public_radar`, `ghost_mode`, `show_city`) are safely stored in `public.profile_private.privacy_settings` JSONB.
- `get_privacy_settings()`: Returns caller's privacy settings safely, falling back to defaults if unconfigured.
- `update_privacy_settings(p_settings JSONB)`: Merges updated privacy keys into `profile_private.privacy_settings` atomically for `auth.uid()`.
- Protected profile columns (`id`, `date_of_birth`, `is_verified`, `is_suspended`) are completely immutable from client RPCs.

---

## Phase 6 Production Hardening & Multi-Account Security Audit (`018_phase6_production_hardening.sql`)

### 25. Complete Table RLS & Function Search Path Enforcement
- **100% RLS Coverage**: All 24 tables in the `public` schema have Row Level Security enabled (`rowsecurity = true`). Zero tables permit unauthenticated or bypass access.
- **Function search_path Hardening**: All 37 database functions enforce explicit schema isolation (`SET search_path = public, pg_temp;`) to eliminate search path spoofing vulnerabilities.
- **Anonymous Key Protection**: The client bundles only the public anonymous key (`ANON`). All sensitive administrative operations (e.g. account cascading deletion, moderation queue resolution) require verified Bearer JWT tokens with verified permissions.

### 26. Deep Link & Authentication Callback Security
- Handled exclusively through custom URL scheme `melsava://` (`auth-callback` and `reset-password`).
- Route transitions are sanitized in `AppRouter.computeRedirect`, prohibiting unauthenticated users from bypassing onboarding or eligibility guards.
- Password updates require authenticated session or verified recovery token, enforcing minimum 6-character length before transmitting to Supabase Auth.

### 27. Offline Data Isolation
- Local offline caching is limited to public experience feed metadata in `SharedPreferences`.
- Zero private PII, unread messages, or conversation histories are cached in unencrypted flat files.
- Mutations strictly require online status; offline state blocks writing to prevent inconsistent or out-of-order state synchronizations.


