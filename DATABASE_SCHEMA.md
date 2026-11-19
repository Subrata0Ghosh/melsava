# MELSAVA — Database Schema Documentation

> Complete reference for the Supabase/PostgreSQL database schema.

---

## Entity-Relationship Overview

```
auth.users ──1:1──▶ profiles ──1:1──▶ profile_private
                       │
         ┌─────────────┼─────────────────────────┐
         │             │                         │
    profile_interests  profile_intentions    device_tokens
         │             │
    interests      intentions
         
profiles ──hosts──▶ experiences ──▶ experience_sessions
                       │
         ┌─────────────┼──────────────────┐
         │             │                  │
  experience_members  experience_prompts  post_experience_choices
                       │
                  experience_answers

post_experience_choices ──mutual──▶ connections ──▶ conversations
                                                       │
                                              conversation_members
                                                       │
                                                    messages

profiles ──▶ blocks
profiles ──▶ reports ──▶ moderation_actions
```

---

## Tables Reference

### 1. `profiles`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | FK → auth.users(id) ON DELETE CASCADE | Same as auth user ID |
| `display_name` | TEXT | NOT NULL, 2–50 chars | Public display name |
| `avatar_url` | TEXT | — | Profile picture URL |
| `bio` | TEXT | max 500 chars | Short biography |
| `city` | TEXT | — | User's city |
| `is_verified` | BOOLEAN | DEFAULT FALSE | Identity verified flag |
| `is_suspended` | BOOLEAN | DEFAULT FALSE | Account suspension flag |
| `onboarding_completed` | BOOLEAN | DEFAULT FALSE | Onboarding flow completed |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() | Last update (auto-trigger) |

**Indexes:** city, is_verified (partial)

---

### 2. `profile_private`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Row ID |
| `user_id` | UUID | UNIQUE, FK → profiles(id) | Owning user |
| `date_of_birth` | DATE | — | Date of birth |
| `email` | TEXT | — | Email address |
| `age_verified` | BOOLEAN | DEFAULT FALSE | Age verification flag |
| `terms_accepted_at` | TIMESTAMPTZ | — | When terms were accepted |
| `guidelines_accepted_at` | TIMESTAMPTZ | — | When guidelines were accepted |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

---

### 3. `interests`

Reference table for user interests.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Interest ID |
| `name` | TEXT | NOT NULL, UNIQUE | Interest name |
| `icon` | TEXT | — | Icon identifier |
| `category` | TEXT | — | Grouping category |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

**Indexes:** category

---

### 4. `profile_interests`

Join table between profiles and interests.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Row ID |
| `profile_id` | UUID | FK → profiles(id) | User profile |
| `interest_id` | UUID | FK → interests(id) | Selected interest |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

**Unique:** (profile_id, interest_id)

---

### 5. `intentions`

Reference table for relationship intentions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Intention ID |
| `name` | TEXT | NOT NULL, UNIQUE | Intention name |
| `description` | TEXT | — | Description |
| `category` | TEXT | NOT NULL, CHECK (friendship/dating) | Category |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

---

### 6. `profile_intentions`

Join table between profiles and intentions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Row ID |
| `profile_id` | UUID | FK → profiles(id) | User profile |
| `intention_id` | UUID | FK → intentions(id) | Selected intention |
| `is_primary` | BOOLEAN | DEFAULT FALSE | Primary intention flag |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

**Unique:** (profile_id, intention_id)

---

### 7. `activity_categories`

Reference table for experience categories.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Category ID |
| `name` | TEXT | NOT NULL, UNIQUE | Category name |
| `description` | TEXT | — | Description |
| `icon` | TEXT | — | Icon identifier |
| `color` | TEXT | — | Hex color code |
| `display_order` | INTEGER | DEFAULT 0 | Sort order |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

---

### 8. `experiences`

Core table for group activities/events.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Experience ID |
| `title` | TEXT | NOT NULL, 3–120 chars | Event title |
| `description` | TEXT | — | Event description |
| `cover_image_url` | TEXT | — | Cover image URL |
| `category_id` | UUID | FK → activity_categories(id) | Category |
| `host_id` | UUID | NOT NULL, FK → profiles(id) | Event host |
| `city` | TEXT | — | Event city |
| `venue_name` | TEXT | — | Venue name |
| `venue_address` | TEXT | — | Full address |
| `is_online` | BOOLEAN | DEFAULT FALSE | Virtual event flag |
| `max_participants` | INTEGER | CHECK > 0 | Capacity limit (NULL = unlimited) |
| `status` | ENUM | draft/published/completed/cancelled | Event status |
| `starts_at` | TIMESTAMPTZ | — | Start time |
| `ends_at` | TIMESTAMPTZ | — | End time (must be > starts_at) |
| `duration_minutes` | INTEGER | CHECK > 0 | Duration in minutes |
| `cancellation_policy` | TEXT | — | Cancellation terms |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() | Last update (auto-trigger) |

**Indexes:** host_id, category_id, status, city, starts_at

---

### 9. `experience_sessions`

Individual sessions within a recurring experience.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Session ID |
| `experience_id` | UUID | FK → experiences(id) | Parent experience |
| `session_date` | TIMESTAMPTZ | NOT NULL | Session date/time |
| `status` | TEXT | CHECK (scheduled/in_progress/completed/cancelled) | Session status |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

---

### 10. `experience_members`

Participants in an experience.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Row ID |
| `experience_id` | UUID | FK → experiences(id) | Experience |
| `user_id` | UUID | FK → profiles(id) | Participant |
| `status` | ENUM | joined/waitlisted/cancelled/attended | Membership status |
| `joined_at` | TIMESTAMPTZ | DEFAULT now() | When joined |
| `cancelled_at` | TIMESTAMPTZ | — | When cancelled |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

**Unique:** (experience_id, user_id)

---

### 11. `experience_prompts`

Conversation prompts for an experience.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Prompt ID |
| `experience_id` | UUID | FK → experiences(id) | Parent experience |
| `prompt_text` | TEXT | NOT NULL | The question/prompt |
| `display_order` | INTEGER | DEFAULT 0 | Display order |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

---

### 12. `experience_answers`

User answers to experience prompts.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Answer ID |
| `prompt_id` | UUID | FK → experience_prompts(id) | Parent prompt |
| `user_id` | UUID | FK → profiles(id) | Answering user |
| `answer_text` | TEXT | NOT NULL | The answer |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

**Unique:** (prompt_id, user_id)

---

### 13. `post_experience_choices`

After an experience, each user chooses how they feel about each other participant.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Choice ID |
| `experience_id` | UUID | FK → experiences(id) | Experience |
| `chooser_id` | UUID | FK → profiles(id) | User making choice |
| `chosen_id` | UUID | FK → profiles(id) | User being chosen |
| `choice_type` | ENUM | friendship/activity_partner/explore_dating/no_connection | Type of connection desired |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

**Unique:** (experience_id, chooser_id, chosen_id)  
**Check:** chooser_id ≠ chosen_id

---

### 13.1. `post_experience_submissions` (Migration 009)

Tracks final submitted status per user per experience to guarantee idempotent submissions and prevent resubmissions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Submission ID |
| `experience_id` | UUID | FK → experiences(id) ON DELETE CASCADE | Associated experience |
| `user_id` | UUID | FK → profiles(id) ON DELETE CASCADE | Submitting user |
| `submitted_at` | TIMESTAMPTZ | DEFAULT now() | Time submitted |

**Unique:** (experience_id, user_id)  
**Index:** `idx_pes_exp_user` on `(experience_id, user_id)`

---

### 13.2. `app_notifications` (Migration 009)

Stores in-app notifications (e.g. mutual connection alerts) without external paid push dependencies.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Notification ID |
| `user_id` | UUID | FK → profiles(id) ON DELETE CASCADE | Recipient user |
| `type` | TEXT | NOT NULL | Notification type (e.g. `mutual_connection`) |
| `title` | TEXT | NOT NULL | Alert title |
| `message` | TEXT | NOT NULL | Alert message content |
| `connection_id` | UUID | FK → connections(id) ON DELETE SET NULL | Associated connection |
| `experience_id` | UUID | FK → experiences(id) ON DELETE SET NULL | Associated experience |
| `read_at` | TIMESTAMPTZ | NULL | Timestamp when read |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

**Index:** `idx_notifications_user_created` on `(user_id, created_at DESC)`

---

### 14. `connections`

Mutual connections created from matching post-experience choices.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Connection ID |
| `user_a_id` | UUID | FK → profiles(id) | First user (lower UUID) |
| `user_b_id` | UUID | FK → profiles(id) | Second user (higher UUID) |
| `connection_type` | TEXT | NOT NULL | Type of connection |
| `experience_id` | UUID | FK → experiences(id) | Originating experience |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

**Unique:** (user_a_id, user_b_id)  
**Checks:** user_a_id ≠ user_b_id, user_a_id < user_b_id (canonical ordering)

---

### 15. `conversations`

Chat conversations tied to connections.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Conversation ID |
| `connection_id` | UUID | UNIQUE, FK → connections(id) | Associated connection |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() | Last update (auto-trigger) |

---

### 16. `conversation_members`

Members of a conversation.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Row ID |
| `conversation_id` | UUID | FK → conversations(id) | Conversation |
| `user_id` | UUID | FK → profiles(id) | Member |
| `joined_at` | TIMESTAMPTZ | DEFAULT now() | When joined |

**Unique:** (conversation_id, user_id)

---

### 17. `messages`

Chat messages within conversations.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Message ID |
| `conversation_id` | UUID | FK → conversations(id) | Conversation |
| `sender_id` | UUID | FK → profiles(id) | Message sender |
| `content` | TEXT | NOT NULL, non-empty | Message content |
| `is_read` | BOOLEAN | DEFAULT FALSE | Read receipt |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Sent timestamp |

**Indexes:** conversation_id, sender_id, created_at (DESC), unread (partial)

---

### 18. `blocks`

User blocking system.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Block ID |
| `blocker_id` | UUID | FK → profiles(id) | User who blocked |
| `blocked_id` | UUID | FK → profiles(id) | User who is blocked |
| `reason` | TEXT | — | Reason for blocking |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

**Unique:** (blocker_id, blocked_id)  
**Check:** blocker_id ≠ blocked_id

---

### 19. `reports`

Content/user reporting system.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Report ID |
| `reporter_id` | UUID | FK → profiles(id) | Reporting user |
| `reported_user_id` | UUID | FK → profiles(id) | Reported user |
| `reported_content_type` | TEXT | — | Type of content (e.g., "message", "profile") |
| `reported_content_id` | UUID | — | ID of reported content |
| `reason` | TEXT | NOT NULL | Reason for report |
| `description` | TEXT | — | Detailed description |
| `status` | ENUM | pending/reviewed/resolved/dismissed | Report status |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |
| `resolved_at` | TIMESTAMPTZ | — | Resolution timestamp |

**Check:** reporter_id ≠ reported_user_id

---

### 20. `moderation_actions`

Actions taken by moderators/admins on users.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Action ID |
| `user_id` | UUID | FK → profiles(id) | Affected user |
| `action_type` | ENUM | warning/suspension/ban | Type of action |
| `reason` | TEXT | NOT NULL | Reason for action |
| `performed_by` | UUID | FK → profiles(id) | Admin who performed action |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |
| `expires_at` | TIMESTAMPTZ | — | Expiration (for time-limited actions) |

---

### 21. `device_tokens`

Push notification tokens.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID (PK) | DEFAULT gen_random_uuid() | Token ID |
| `user_id` | UUID | FK → profiles(id) | Owning user |
| `token` | TEXT | NOT NULL | Device push token |
| `platform` | TEXT | CHECK (ios/android/web) | Device platform |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | Row creation time |

**Unique:** (user_id, token)

---

## Custom Enum Types

| Type | Values |
|------|--------|
| `experience_status` | draft, published, completed, cancelled |
| `member_status` | joined, waitlisted, cancelled, attended |
| `choice_type` | friendship, activity_partner, explore_dating, no_connection |
| `report_status` | pending, reviewed, resolved, dismissed |
| `moderation_action_type` | warning, suspension, ban |

---

## Key Relationships

1. **User ↔ Profile**: 1:1 via `profiles.id → auth.users.id`
2. **Profile ↔ Private Data**: 1:1 via `profile_private.user_id → profiles.id`
3. **Profile ↔ Interests**: M:N via `profile_interests` join table
4. **Profile ↔ Intentions**: M:N via `profile_intentions` join table
5. **Profile → Experiences (host)**: 1:N via `experiences.host_id → profiles.id`
6. **Experience ↔ Members**: M:N via `experience_members` join table
7. **Experience → Prompts → Answers**: 1:N:N chain
8. **Experience → Choices → Connections**: Post-experience flow
9. **Connection → Conversation → Messages**: 1:1:N chain
10. **Profile → Blocks/Reports**: 1:N self-referencing

---

## Server-Side Functions

| Function | Migration | Description |
|----------|-----------|-------------|
| `create_profile_on_signup()` | 001 | Trigger on `auth.users` INSERT — auto-creates profile + profile_private |
| `check_experience_capacity(UUID)` | 003 | Returns JSON with capacity status for an experience |
| `process_mutual_connections(UUID)` | 003 | Legacy mutual connections processor (superseded by migration 009) |
| `handle_updated_at()` | 001 | Trigger function to auto-update `updated_at` timestamps |
| `complete_profile_onboarding(...)` | 006 | Atomic: saves profile, private data, interests, intentions; verifies age |
| `get_experience_participant_counts(UUID[])` | 006 | Aggregate: returns joined & waitlisted counts without exposing PII |
| `join_experience(UUID)` | 006 | Atomic: row-locked (`FOR UPDATE`) capacity check, join or FIFO waitlist |
| `cancel_experience_membership(UUID)` | 006 | Atomic: row-locked (`FOR UPDATE`) cancellation with FIFO waitlist promotion |
| `complete_experience_and_mark_attendance(UUID, UUID[])` | 009 | Atomic: host-only validation, completes experience and marks verified attendees |
| `get_host_joined_participants(UUID)` | 009 | Host-only: lists joined participants for attendance review |
| `fetch_eligible_reconnect_attendees(UUID)` | 009 | Privacy-safe: returns only attended peers, excludes blocked/suspended, zero PII |
| `fetch_reconnect_submission_status(UUID)` | 009 | Gating: returns completion, attendance, host, and submission status |
| `submit_post_experience_choices(UUID, JSONB)` | 009 | Atomic: exact matching (Friendship=Friendship, Dating=Dating), creates canonical connections, conversations, and notifications |

---

## Performance & Concurrency Indexes (Migrations 006 & 009)

| Index Name | Table | Columns | Purpose |
|------------|-------|---------|---------|
| `idx_experiences_published_starts_at` | `experiences` | `(status, starts_at)` | Accelerates published upcoming feed queries |
| `idx_experience_members_exp_status_fifo` | `experience_members` | `(experience_id, status, joined_at, created_at, id)` | Ensures indexed FIFO waitlist promotion and fast capacity calculation |
| `idx_pes_exp_user` | `post_experience_submissions` | `(experience_id, user_id)` | Fast lookup and uniqueness verification for submission gating |
| `idx_notifications_user_created` | `app_notifications` | `(user_id, created_at DESC)` | Efficient in-app notification feed sorting and badge counts |

---

## Seed Data

| Table | Count | Content |
|-------|-------|---------|
| `activity_categories` | 12 | Coffee, Board Games, Nature, Sports, Photo, Music, Art, Food, Books, Volunteering, Learning, Cultural |
| `intentions` | 7 | Friendship, Activity Partner, Casual/Meaningful/Serious Dating, Marriage-minded, Open |
| `interests` | 18 | Travel, Cooking, Reading, Fitness, Music, Photography, Hiking, Movies, Gaming, Yoga, Dancing, Art, Tech, Volunteering, Meditation, Languages, Gardening, Coffee |
| `experiences` | 10 | Sample events (created only if a profile exists) |
