# MELSAVA Development Roadmap & Execution Tracker

This roadmap tracks the incremental delivery of MELSAVA following the specification in `idea.txt`.

---

## Phase 1 — Foundation (Current)
- [x] Flutter project initialization with clean architecture.
- [x] Feature-first directory structure (`features/`, `core/`, `shared/`, `app/`).
- [x] Brand typography configuration (`Manrope` + `Inter`).
- [x] Palette tokens definition (`Warm Ivory`, `Deep Plum`, `Mauve`, `Soft Coral`, `Sage`).
- [x] ThemeData configuration with custom card/button styling.
- [x] Brand constants and abstract vector logo implementation.
- [x] Reusable widget primitives (`PrimaryButton`, `SecondaryButton`, `CustomTextField`, `EmptyStateWidget`, etc.).
- [x] Complete GoRouter navigation shell with persistent 5-tab bottom navigation bar.
- [x] Authentication screens (Welcome, Sign In, Sign Up, Forgot Password, Verification).
- [x] Supabase service provider & local environment mock fallback.
- [x] PostgreSQL database migrations (`001_initial_schema.sql` to `004_seed_data.sql`).
- [x] Core documentation suite (`README.md`, `PRODUCT_OVERVIEW.md`, `APP_WORKFLOW.md`, `DESIGN_SYSTEM.md`, `SECURITY_AND_RLS.md`).

---

## Phase 2 — Onboarding & Adult Eligibility
- [ ] Age verification gate (18+ certification & confirmation modal).
- [ ] Multi-step profile setup wizard:
  - Step 1: Display name & avatar picker.
  - Step 2: Location (City / broad neighborhood).
  - Step 3: Bio & conversational icebreakers.
  - Step 4: Interests multi-select (15+ curated topics).
  - Step 5: Primary & secondary connection intentions.
  - Step 6: Community safety pledge & terms acceptance.
- [ ] Persistence to `profiles` and `profile_private` via Supabase.

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
