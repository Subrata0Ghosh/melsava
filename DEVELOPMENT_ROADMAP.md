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

## Phase 3 — Post-Experience Mutual Choice System (Planned)
- [ ] Experience completion trigger & attendee attendance confirmation.
- [ ] Private participant selection screen ("Who would you like to meet again?").
- [ ] Choice options: Friendship, Activity Partner, Explore Dating, No Connection.
- [ ] Encrypted submission to `post_experience_choices`.
- [ ] Server-side execution of `process_mutual_connections()`.
- [ ] Celebration popup & notification when a mutual connection is unlocked.

---

## Phase 4 — Connections & Realtime Messaging (Planned)
- [ ] Connections tab: Grid of mutual connections grouped by experience.
- [ ] Conversation thread screen:
  - Text messages with real-time Supabase Realtime subscriptions.
  - Read status ticks.
  - Friendly connection context banner ("Met at Coffee & Conversation").
- [ ] In-chat blocking & safety reporting actions.

---

## Phase 5 — Safety, Moderation & Account Settings (Planned)
- [ ] User profile viewer & editor.
- [ ] Block list management & immediate unmatching.
- [ ] Content reporting dialog with categorized reasons.
- [ ] Account deletion (GDPR/privacy-compliant erasure cascade).
- [ ] Community Guidelines viewer.

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
