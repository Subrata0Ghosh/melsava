# MELSAVA Development Roadmap & Execution Tracker

This roadmap tracks the incremental delivery of MELSAVA following the specification in `idea.txt`.

---

## Phase 1 — Foundation, Authentication & Hardened Onboarding (Completed)
- [x] Flutter project initialization with clean architecture.
- [x] Feature-first directory structure (`features/`, `core/`, `shared/`, `app/`).
- [x] Brand typography configuration (`Manrope` + `Inter`).
- [x] Palette tokens definition (`Warm Ivory`, `Deep Plum`, `Mauve`, `Soft Coral`, `Sage`).
- [x] ThemeData configuration with Light and Dark theme support.
- [x] Brand constants and abstract vector logo implementation.
- [x] Reusable widget primitives (`PrimaryButton`, `SecondaryButton`, `CustomTextField`, `GoogleSignInButton`, `EmptyStateWidget`, etc.).
- [x] Authentication-aware GoRouter navigation with redirects and persistent 5-tab bottom navigation bar.
- [x] Authentication screens (Welcome, Sign In without hard-coded demo credentials, Sign Up, Forgot Password, Email Verification, Native Google Sign-In).
- [x] Adult eligibility gate (18+ Date of Birth validation, underage access blocking, private `profile_private.date_of_birth` persistence).
- [x] Multi-step profile onboarding wizard (`ProfileOnboardingScreen`):
  - Step 1: Display name & profile photo upload to Supabase Storage (`avatars` bucket).
  - Step 2: Broad location (city/area) & short bio.
  - Step 3: Interests multi-select & preferred activity categories.
  - Step 4: Primary & secondary connection intentions.
  - Step 5: Availability & discovery preferences (age range, distance radius, format).
  - Step 6: Community safety pledge & guidelines acceptance.
- [x] Fixed Phase 1 data-integrity bug: onboarding is never marked complete if interest or intention saves fail; atomic RPC / fail-fast ordered writes prevent duplicates on retry.
- [x] Automated test suite covering auth, verification, onboarding, and Dark/Light modes (`phase1_auth_onboarding_test.dart`).

---

## Phase 2 — Live Experience Discovery, Joining & My Circles (Completed)
- [x] **Database Migration & Concurrency RPCs (`006_phase2_experiences_rls_and_rpc.sql`)**:
  - Composite indexes `idx_experiences_published_starts_at` and `idx_experience_members_exp_status_fifo`.
  - Atomic `complete_profile_onboarding(...)` RPC ensuring transactional onboarding completion.
  - Aggregate-only `get_experience_participant_counts(UUID[])` RPC protecting member PII from unjoined users.
  - Atomic `join_experience(UUID)` RPC with `FOR UPDATE` lock, adult eligibility verification, duplicate prevention, and automatic capacity waitlisting.
  - Atomic `cancel_experience_membership(UUID)` RPC with `FOR UPDATE` lock, membership cancellation, and FIFO waitlist promotion.
  - Tightened `experience_members` RLS: client direct insert/update dropped, host attendance marking secured.
- [x] **Real Supabase Experiences Repository (`experiences_repository.dart`)**:
  - Live queries for published, upcoming experiences (excluding draft, cancelled, and past).
  - Pure static filter and ranking engine (`applyFiltersAndRanking`): search title/desc, categories, format (online vs in-person), available spots, and inexpensive user interest/city ranking.
  - Grouping engine (`groupMyExperiences`): partitions into Upcoming, Waitlisted, Attended, Past, excluding cancelled.
  - Shared Riverpod providers (`publishedExperiencesProvider`, `myExperiencesProvider`, `experienceDetailProvider`, `experienceActionControllerProvider`).
- [x] **Discover Screen (`discover_screen.dart`)**:
  - Connected to live Supabase feed with live categories, search, intent filters, and interactive Area Radar.
  - Real 3D Stacked Trending Cards Deck and featured upcoming experience card.
  - Loading, error with retry, and empty states in Light & Dark modes.
- [x] **Experience Details Screen (`experience_detail_sheet.dart`)**:
  - Full-screen route with live capacity chips, duration, venue/online details, host bio, and cancellation policy.
  - Dynamic sticky CTA bar: `Join Experience →`, `Join Waitlist →`, `Joined ✓` + `Cancel RSVP` confirmation, `On Waitlist` + `Leave Waitlist`.
- [x] **Join Confirmation Flow (`join_experience_sheet.dart`)**:
  - Live atomic server-side join confirmation with duplicate-tap prevention.
  - Removed unused hard-coded Dating intent picker; shows saved profile intentions read-only.
  - Progress feedback, error with Retry, and confirmed Joined/Waitlisted success state.
- [x] **My Circles Screen (`experiences_screen.dart`)**:
  - Real Supabase experience management organized into **Upcoming**, **Waitlisted**, **Attended**, and **Past** sub-tabs with live count badges.
  - Confirmation dialog and atomic server cancellation with FIFO waitlist promotion.
  - Loading, error with retry, and empty states.
- [x] **Automated Verification**:
  - `phase2_experiences_test.dart` passing 12 comprehensive unit and widget tests.
  - 39 total test suites passing across the workspace.
  - `flutter analyze` with 0 issues.

---

## Phase 3 — Real Attendance, Private Mutual Choice & Connection Creation (Completed)
- [x] **Database Migrations & Concurrency RPCs (`009_phase3_attendance_and_mutual_choices.sql`)**:
  - `post_experience_submissions` table + RLS enforcing idempotent final submission per user per experience.
  - `app_notifications` table + RLS for in-app mutual match notifications without paid push dependencies.
  - Tightened RLS on `post_experience_choices`: client direct inserts/updates dropped; server-only atomic writes.
  - Atomic `complete_experience_and_mark_attendance(UUID, UUID[])` RPC: host-only validation, experience completion, and attendee verification.
  - Host review RPC `get_host_joined_participants(UUID)`: returns only joined participants for attendance marking.
  - Real attendee discovery RPC `fetch_eligible_reconnect_attendees(UUID)`: zero PII, filters blocked/suspended, returns only attended peers.
  - Status gating RPC `fetch_reconnect_submission_status(UUID)`: gating for eligibility, attendance, host status, and submission completion.
  - Atomic matching RPC `submit_post_experience_choices(UUID, JSONB)`:
    - Enforces strict **exact matching consent**: Friendship=Friendship, Activity=Activity, Dating=Dating.
    - Zero auto-promotion to dating on mismatched positive choices.
    - Silent no-connection on passes or one-sided choices; zero rejection notifications.
    - Atomically creates canonical `connections` (`user_a_id < user_b_id`), `conversations`, `conversation_members`, and `app_notifications`.
- [x] **Real Post-Experience Repository & Riverpod Architecture (`post_experience_repository.dart`)**:
  - Typed models (`EligibleAttendee`, `ReconnectChoiceType`, `PostExperienceChoiceInput`, `MutualConnectionResult`, `PostExperienceSubmissionResult`, `ReconnectSubmissionStatus`, `HostParticipantItem`).
  - Providers: `reconnectSubmissionStatusProvider`, `eligibleAttendeesProvider`, `hostJoinedParticipantsProvider`, `postExperienceActionControllerProvider`.
- [x] **Host Attendance Sheet UI (`host_attendance_sheet.dart`)**:
  - Bottom sheet accessible to verified hosts from My Circles and Experience Hub.
  - Real joined participant roster with "Select All" toggle, individual checkboxes, attendee counts, and atomic submission.
- [x] **Production Reconnect Screen (`post_experience_choice_screen.dart`)**:
  - Removed all hard-coded demo profiles, fake Future.delayed delays, and artificial celebration popups.
  - Full support for 8 states: Loading, Available Attendees (defaults to No Connection), Submitting, Success without Match, Mutual Match Celebration (`MutualMatchCelebrationDialog`), Already Submitted, Not Eligible, Experience Not Completed, and Network Error.
  - Pre-submission choice review sheet with privacy reassurance.
- [x] **Automated Verification**:
  - `phase3_post_experience_test.dart` passing 9 comprehensive unit and widget tests.
  - 48 total tests passing across all suites (`flutter test`).
  - `flutter analyze` passing with 0 warnings or errors.

---

## Phase 4 — Connections, Supabase Realtime Chat & Read Receipts (Completed)
- [x] **Phase 3 Database Hardening (`012_phase3_hardening.sql`)**:
  - Hardened `complete_experience_and_mark_attendance(UUID, UUID[])`:
    - Enforced host authentication (`auth.uid()`).
    - Row-level lock (`FOR UPDATE`) on parent experience to prevent race conditions.
    - Verified scheduled completion: requires `now() >= ends_at` or `now() >= starts_at + (duration_minutes * '1 minute'::INTERVAL)`.
    - Strict validation on entire attendee array: rejects duplicates and non-joined memberships atomically.
    - Idempotent safe return on already completed experiences without modifying finalized records.
  - Hardened `submit_post_experience_choices(UUID, JSONB)`:
    - Row lock (`FOR UPDATE`) on parent experience serializing concurrent reciprocal submissions.
    - Strict validation: rejects self-selection, non-attendees, duplicate entries, and invalid choice types.
    - Preserves exact compatibility rules (Friendship=Friendship, Activity=Activity, Dating=Dating; different intentions = no connection, no upgrades).
    - Idempotent safe retry without duplicate connections, conversations, or notifications.
- [x] **Phase 4 Database RPCs & Security (`013_phase4_connections_and_realtime.sql`)**:
  - Secure helper function `can_access_conversation(p_conversation_id UUID)` checking membership, mutual connection validity, absence of blocks in either direction, and account active status.
  - Hardened RLS policies for `conversations`, `conversation_members`, and `messages`.
  - RPC `get_user_connections()`: returns authenticated user's mutual connections, originating experience title, and genuine last message (no fake online badges or fabricated compatibility scores).
  - RPC `get_user_inbox_threads()`: returns real active threads with genuine unread message counts (`is_read = FALSE`).
  - RPC `get_conversation_messages(p_conversation_id, p_limit, p_before)`: paginated chronological message history.
  - RPC `get_or_create_conversation_for_connection(p_connection_id)`: safe retrieval or creation of 2-member conversation for mutual connections.
  - RPC `send_conversation_message(p_conversation_id, p_content)`: server-side sender ID enforcement (`auth.uid()`), whitespace trimming, and 1,000 character maximum limit.
  - RPC `mark_conversation_read(p_conversation_id)`: atomic read receipt marking for incoming peer messages.
  - Realtime publication: `messages` added to `supabase_realtime` publication with `REPLICA IDENTITY FULL`.
- [x] **Connections Repository & Riverpod Architecture (`connections_repository.dart`)**:
  - Real data models: `ConnectionModel`, `InboxThreadModel`, `ChatMessageModel` (with `isMe`, `isRead`, `time`, and `copyWith`).
  - `subscribeToConversationMessages` stream listener filtering on `conversation_id`.
  - `markConversationRead` method for atomic read receipts.
  - Clean error propagation and Riverpod state management (`userConnectionsProvider`, `inboxThreadsProvider`, `conversationMessagesProvider`).
- [x] **Connections Screen (`connections_screen.dart`)**:
  - Removed all fake online dots and synthetic compatibility scores.
  - Real connection cards with partner name, avatar, bio, connection type badge, originating experience context, and last message snippet.
  - Filter tabs (All, Friends, Activity, Dates) with real live counts.
  - Cosmic Orbit View support with real connection models.
- [x] **Inbox Screen (`inbox_screen.dart`)**:
  - Removed all fake online indicators.
  - Real conversation threads displaying partner name, avatar, connection type badge, shared experience name, last message preview, and real unread count badge.
- [x] **Conversation Screen (`conversation_screen.dart`)**:
  - Removed demo fallback messages; handles empty state with structured icebreaker suggestions.
  - Context banner displaying dynamic originating experience title ("You both reconnected after...").
  - Realtime messaging with instant optimistic append, deduplication, and auto-marking incoming messages as read.
  - Real read receipts: single check (`Icons.check_rounded`) for delivered, double check (`Icons.done_all_rounded` in `AppColors.mintAccent`) for read.
  - Message draft preservation on send failure with user retry SnackBar.
  - In-chat safety actions (Report and Block) with confirmation dialogs and immediate provider cache invalidation.
- [x] **Automated Verification**:
  - `phase4_connections_and_chat_test.dart` passing 11 comprehensive unit and widget tests.
  - `phase3_post_experience_test.dart` passing 19 unit, widget, and hardening regression tests.
  - 80 total tests passing across all test suites (`flutter test`).
  - `flutter analyze` passing with 0 warnings or errors.

---

## Phase 5 — Safety, Moderation, Profile Management & Account Settings (Completed)
- [x] **Phase 4 Security Preflight & Database RPCs (`014_phase5_safety_and_profile.sql`)**:
  - Dropped client direct `INSERT` and `UPDATE` policies on `public.messages` and revoked direct mutation privileges from `anon` and `authenticated`.
  - Strengthened `can_access_conversation(UUID)` to verify active session, caller & partner non-suspended profile state, and non-existence of blocks in either direction.
  - Implemented atomic `update_user_profile(...)` RPC updating `profiles`, `profile_interests`, `profile_intentions`, and `profile_private` preferences without exposing sensitive verification columns.
  - Real block management RPCs: `block_user(UUID)`, `unblock_user(UUID)`, `get_blocked_users()` rejecting self-blocking and duplicate blocks.
  - Real content reporting RPC: `submit_user_report(UUID, TEXT, TEXT, TEXT, UUID)` enforcing 9 canonical reasons, 500-character description limit, and confidential reporter storage.
  - Moderation infrastructure: `public.moderators` table, `is_moderator()` helper, `get_moderation_reports()` query, `resolve_moderation_report()` resolution, and `apply_moderation_action()` recording actions with immediate account suspension support.
  - Permanent account deletion RPC: `delete_user_account_permanent(TEXT)` requiring explicit `'DELETE'` confirmation keyword, cascading all profile FKs, and cleaning auth users.
- [x] **Supabase Edge Function (`supabase/functions/delete-account/index.ts`)**:
  - Deno edge function validating Bearer JWT, removing user avatar storage objects from `avatars` bucket, purging user rows, and invoking Supabase Admin Auth API (`auth.admin.deleteUser`).
- [x] **Auth & Profile Management (`auth_repository.dart`, `app_user.dart`)**:
  - Extended `AppUser` model with `isVerified` and `isSuspended` fields.
  - Hydrated `is_verified` and `is_suspended` flags from Supabase `public.profiles`.
  - Implemented `uploadAvatar(file)` uploading custom photo to Supabase Storage `avatars/${userId}/...`.
  - Implemented atomic `updateProfile` calling `update_user_profile` RPC.
  - Completely eradicated the dangerous `from('profiles').delete()` fallback; throws on error without premature sign out or cache wipe.
- [x] **Real Profile Viewer & Editor (`profile_screen.dart`, `edit_profile_sheet.dart`)**:
  - Replaced demo fallback ("Sneha") with real authenticated user profile data.
  - Enforced verified badge visibility exclusively when `user.isVerified == true`.
  - Displayed real experience and mutual connection counts; eliminated fake "12 followers" metric.
  - Replaced fake "Go Premium" card with real Interests & Passions chips, intentions, and Community Guidelines link.
  - Edit Profile Sheet supports custom avatar upload via `ImagePicker`, display name validation (2-50 chars), bio, city, intentions, and interest selections.
- [x] **Block Management & Blocked Profiles Screen (`blocked_profiles_screen.dart`)**:
  - Screen displaying real blocked users, avatars, and blocked dates with loading, empty, and error states.
  - Unblock action with `ConfirmationDialog` and cache invalidation across connections and inbox threads.
- [x] **Confidential Reporting System (`report_dialog.dart`)**:
  - Updated to 9 canonical reasons with 500-character max limit and character counter.
  - Asynchronous submission with loading spinner, disabled double-tap prevention, and error-retaining state.
  - Direct shortcut linking to Community Guidelines.
- [x] **Community Guidelines Screen (`community_guidelines_screen.dart`)**:
  - 10 comprehensive guidelines for authentic identity, vetted public venues, consent, punctuality, and anti-harassment.
  - Accessible from Settings, Profile, and Report dialogs.
- [x] **Moderation Management Screen (`moderation_screen.dart`)**:
  - Restricted to authenticated moderators (`isModeratorProvider`).
  - Interactive status tabs (Pending, Reviewed, Resolved, Dismissed, All).
  - Moderator actions: Dismiss, Issue Formal Warning, and Suspend Account.
- [x] **Settings Screen Audit (`settings_screen.dart`)**:
  - Replaced fake SMS 2FA switch with clear informational TOTP tile.
  - Replaced fake remote device sessions with real current session information.
  - Wired real blocked count and direct navigation to `/blocked-profiles`.
  - Connected direct navigation to `/community-guidelines` and conditional `/moderation` tile for moderators.
  - Hardened account deletion with clear error handling.
- [x] **Automated Verification**:
  - `phase5_safety_and_settings_test.dart` passing comprehensive unit and widget tests.
  - All test suites passing in `flutter test`.
  - `flutter analyze` passing with 0 warnings or errors.

---

## Phase 6 — Multi-Account Verification & Production Hardening (Planned)
- [ ] Two-account manual verification on live deployed Supabase project.
- [ ] Performance monitoring and query optimization.
- [ ] Edge cases, offline sync, and deep links.

---

## Phase 7 — Closed Beta & Production Launch (Planned)
- [ ] Seed production data for inaugural launch city.
- [ ] Host-curated experience management tools.
- [ ] App Store & Play Store release configurations.
