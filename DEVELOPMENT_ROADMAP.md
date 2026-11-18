# MELSAVA Development Roadmap & Execution Tracker

This roadmap tracks the incremental delivery of MELSAVA following the specification in `idea.txt`.

---

## Phase 1 — Foundation, Authentication & Onboarding (Completed)
- [x] Flutter project initialization with clean architecture.
- [x] Feature-first directory structure (`features/`, `core/`, `shared/`, `app/`).
- [x] Brand typography configuration (`Manrope` + `Inter`).
- [x] Palette tokens definition (`Warm Ivory`, `Deep Plum`, `Mauve`, `Soft Coral`, `Sage`).
- [x] ThemeData configuration with Light and Dark theme support.
- [x] Brand constants and abstract vector logo implementation.
- [x] Reusable widget primitives (`PrimaryButton`, `SecondaryButton`, `CustomTextField`, `GoogleSignInButton`, `EmptyStateWidget`, etc.).
- [x] Authentication-aware GoRouter navigation with redirects and persistent 5-tab bottom navigation bar.
- [x] Authentication screens (Welcome, Sign In without hard-coded demo credentials, Sign Up, Forgot Password, Email Verification, Native Google Sign-In).
- [x] Supabase Auth session as single source of truth (no fake SharedPreferences session restore) and strictly debug-only mock fallback (`kDebugMode`).
- [x] PostgreSQL database migrations (`001_initial_schema.sql` to `005_onboarding_preferences_and_storage.sql`).
- [x] Core documentation suite (`README.md`, `PRODUCT_OVERVIEW.md`, `APP_WORKFLOW.md`, `DESIGN_SYSTEM.md`, `SECURITY_AND_RLS.md`).

---

## Phase 2 — Onboarding & Adult Eligibility (Completed in Phase 1 Implementation)
- [x] Adult eligibility gate (18+ Date of Birth validation, underage access blocking, private `profile_private.date_of_birth` persistence).
- [x] Multi-step profile onboarding wizard (`ProfileOnboardingScreen`):
  - Step 1: Display name & profile photo upload to Supabase Storage (`avatars` bucket).
  - Step 2: Broad location (city/area) & short bio.
  - Step 3: Interests multi-select & preferred activity categories.
  - Step 4: Primary & secondary connection intentions.
  - Step 5: Availability & discovery preferences (age range, distance radius, format).
  - Step 6: Community safety pledge & guidelines acceptance.
- [x] Persistence to `profiles`, `profile_private`, `profile_interests`, `profile_intentions`, and Supabase Storage `avatars` bucket via repository & provider layers.
- [x] Post-login & session-restore routing based on real `isEmailVerified`, `ageVerified`, and `onboardingCompleted` state.
- [x] Clean logout clearing Supabase & Google sessions and returning to Welcome.

---

## Phase 3 — Experience Discovery & Joining
- [ ] Discover screen feed:
  - Hero banner with daily curated experience.
  - Horizontal category scroll chips.
  - Recommended micro-group activities.
- [ ] Experiences tab with search, filters (date, online/in-person, category).
- [ ] Experience details screen:
  - Venue details, public meeting safety tips, host profile, attendee count.
- [ ] Atomic RSVP joining flow with capacity limit enforcement.
- [ ] "My Experiences" tab (Upcoming, Attended, Past).

---

## Phase 4 — Post-Experience Mutual Choice System
- [ ] Experience completion trigger & attendee attendance confirmation.
- [ ] Private participant selection screen ("Who would you like to meet again?").
- [ ] Choice options: Friendship, Activity Partner, Explore Dating, No Connection.
- [ ] Encrypted submission to `post_experience_choices`.
- [ ] Server-side execution of `process_mutual_connections()`.
- [ ] Celebration popup & notification when a mutual connection is unlocked.

---

## Phase 5 — Connections & Realtime Messaging
- [ ] Connections tab: Grid of mutual connections grouped by experience.
- [ ] Conversation thread screen:
  - Text messages with real-time Supabase Realtime subscriptions.
  - Read status ticks.
  - Friendly connection context banner ("Met at Coffee & Conversation").
- [ ] In-chat blocking & safety reporting actions.

---

## Phase 6 — Safety, Moderation & Account Settings
- [ ] User profile viewer & editor.
- [ ] Block list management & immediate unmatching.
- [ ] Content reporting dialog with categorized reasons.
- [ ] Account deletion (GDPR/privacy-compliant erasure cascade).
- [ ] Community Guidelines viewer.

---

## Phase 7 — Testing & Verification
- [ ] Unit tests for Riverpod providers and repositories.
- [ ] Widget tests for core components and screen flows.
- [ ] PostgreSQL RLS policy verification test suite.
- [ ] Two-account mutual choice simulation test.

---

## Phase 8 — Closed Beta & Production Hardening
- [ ] Seed production data for inaugural launch city.
- [ ] Host-curated experience management tools.
- [ ] Crash reporting and performance monitoring integration.
