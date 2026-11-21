# MELSAVA — Complete User Journey

This document describes every step of the MELSAVA user experience, from first launch to ongoing engagement.

---

## A. First Launch Flow

### Splash Screen
1. App opens with the **MELSAVA logo** centred on screen
2. Brand colors (Deep Plum background, Warm Ivory logo)
3. Auto-navigates after ~2 seconds to the Welcome Screen

### Welcome Screen
1. **Primary tagline** displayed: *"Meet through moments."*
2. Brief explanation of the experience-first concept:
   - *"Meet people through experiences, not endless swiping."*
   - *"Discover activities, enjoy genuine moments and choose who you'd like to meet again."*
3. **Get Started** button (primary CTA) → Sign Up flow
4. **Sign In** link → Sign In flow
5. Footer links:
   - Terms of Service
   - Privacy Policy
   - Community Guidelines

---

## B. Authentication Flow

### Sign Up
1. User taps **Get Started**
2. Sign Up screen with:
   - Email address field
   - Password field
   - Confirm password field
   - **Create Account** button
3. On success → Email verification screen
4. Supabase Auth sends a verification email
5. User verifies email → redirected to Adult Eligibility

### Sign In
1. User taps **Sign In**
2. Sign In screen with:
   - Email address field
   - Password field
   - **Sign In** button
   - **Forgot Password?** link
3. On success → Discover screen (if profile complete) or Onboarding (if not)

### Password Reset
1. User taps **Forgot Password?**
2. Enter email address
3. Supabase Auth sends reset email
4. User resets password via email link

### Email Verification
1. Waiting screen with instructions:
   - *"We've sent a verification link to your email."*
   - *"Check your inbox and tap the link to continue."*
2. Resend option available
3. On verification → continue to Adult Eligibility

### Session Persistence
- Auth state persisted across app restarts
- Auto sign-in if session is valid
- Auto redirect to appropriate screen based on profile completion

---

## C. Adult Eligibility

> [!IMPORTANT]
> MELSAVA is exclusively for adults. This step occurs before any profile creation or social interaction.

### Flow
1. Screen explains that MELSAVA is for adults aged 18+
2. User confirms date of birth
3. System validates age ≥ 18
4. If underage → access denied with explanation
5. If eligible → proceed to Profile Onboarding

### Design Decisions
- Exact date of birth is **never publicly exposed**
- The system does **not** claim identity verification based solely on a date entry
- Architecture supports adding a third-party age-verification service later
- Government ID / Aadhaar is **not** collected by default

---

## D. Profile Onboarding (10 Steps)

A friendly, guided multi-step onboarding with a **progress indicator** showing remaining steps.

### Step 1 — Display Name
- Text input for the user's display name
- This is how they appear to other participants

### Step 2 — Profile Photograph
- Upload or capture a profile photo
- Image compression before upload
- Stored in Supabase Storage

### Step 3 — Short Introduction
- Text area for a brief bio
- Example prompt: *"Tell people a little about yourself"*

### Step 4 — Broad City or Area
- Select or type a general location
- **No precise home location** exposed
- Used for matching with local experiences

### Step 5 — Interests
- Select from a curated list of interests (15+ options)
- Multiple selections allowed
- Examples: Travel, Music, Reading, Photography, Cooking, Fitness, Art, Technology, Nature, Games

### Step 6 — Preferred Activities
- Select preferred activity categories from the 12 available
- Helps surface relevant experiences on the Discover screen

### Step 7 — Connection Intentions
- Select one or more intentions:
  1. Genuine friendship
  2. Activity partner
  3. Casual dating
  4. Meaningful dating
  5. Serious relationship
  6. Marriage-minded connection
  7. Open to discovering
- Choose a **primary intention**

### Step 8 — Communication Preferences
- Set preferences for how and when they'd like to communicate
- Notification settings

### Step 9 — Discovery Preferences
- Age range preferences for people they'd like to meet
- Location/distance preferences
- Activity type preferences

### Step 10 — Community Guidelines Acceptance
- Display community guidelines summary
- User must explicitly accept to proceed
- Timestamp recorded for compliance

### Onboarding UX Notes
- Non-essential details can be **skipped** and completed later
- Progress indicator visible throughout
- Users can go back to previous steps
- On completion → Discover screen

---

## E. Discover Screen (Main Home)

The primary entry point of the app.

### Header
- Small **MELSAVA** logo (top-left)
- Greeting (e.g., *"Good morning, Priya"*)
- Notification icon (top-right)
- Broad location selector

### Main Content

**Heading:** *"What would you like to experience?"*

**Subtitle:** *"Good moments start with shared interests."*

### Content Sections (scrollable)
1. **Featured Experience** — Large hero card for a highlighted activity
2. **Browse by Category** — Horizontal scrollable chips/cards for the 12 categories
3. **Experiences Near You** — Cards for local upcoming activities
4. **Recommended Activities** — Personalized based on interests and preferences
5. **People Who Share Your Interests** — Limited, curated profiles (not an endless feed)

> [!NOTE]
> Experience cards are the **visual priority**, not profile photographs. This is not a profile-browsing app.

---

## F. Experience Discovery

### Experiences Tab
A dedicated page for browsing and filtering activities.

### Filters Available
| Filter | Options |
|---|---|
| Category | Any of the 12 categories |
| City / Area | Broad location |
| Date | Specific date or date range |
| Format | Online or In-Person |
| Group Size | Small (3–5), Medium, etc. |
| Available Places | Has open spots |
| Activity Type | Type-specific filters |

### Experience Card Display
Each card shows:
- 📸 Cover image
- 🏷 Category label
- 📝 Experience name
- 📅 Date and time
- 📍 Broad location
- 👥 Group capacity / available spots
- 📄 Brief description
- 👤 Host information
- **Join** or **View Details** button

---

## G. Experience Detail Screen

When a user taps an experience card:

### Information Displayed
- Activity title
- Full description
- Cover photograph (large)
- Date and time
- Duration
- Venue (public location) or online format
- Host name and brief info
- Group size and spots remaining
- Participant info (appropriate level of detail)
- Safety guidance for in-person events
- Cancellation policy

### Actions
- **Join Experience** button (primary CTA)
- Save / bookmark
- Share

### Rules
- Experiences are curated by administrators or approved hosts
- No unrestricted user-created public events in MVP
- In-person activities use **public venues only**
- Sufficient participant and host info provided before attendance

---

## H. Join Experience Flow (Phase 2 Implemented)

### Steps
1. User taps **Join Experience** (or **Join Waitlist** when capacity is full)
2. Bottom sheet opens showing selected experience details, live available capacity, and saved profile intentions (read-only, never defaults to Dating)
3. User confirms RSVP (`join_experience` atomic RPC):
   - Row-level lock (`FOR UPDATE`) on `experiences` prevents overbooking race conditions
   - System validates adult eligibility (`age_verified = TRUE`, `onboarding_completed = TRUE`, `!is_suspended`)
   - Checks published and upcoming status
   - Prevents duplicate joins idempotently
   - Enrolls user into `joined` if spots remain, or enqueues into `waitlisted`
4. Confirmation screen displayed:
   - *"You have joined this experience."* (or *"You're on the waitlist."*)
   - Activity details summary
   - Cancellation policy reminder
5. Experience appears in **My Circles** with immediate status update

### Additional Features
- **Cancel RSVP** — User can cancel participation from Experience Details or My Circles with confirmation (`cancel_experience_membership` RPC)
- **FIFO Waitlist Promotion** — When a joined member cancels, the earliest waitlisted user is automatically promoted to `joined` on the server
- **Leave Waitlist** — Waitlisted users can withdraw their waitlist request anytime with confirmation

---

## H.1. My Circles Management (Phase 2 Implemented)

Located under Tab 2 of the Experiences screen, organized into four functional sections:
1. **Upcoming**: Experiences the user has actively joined, with confirmed RSVP badge, direct link to Experience Details, Open Hub trigger, and Cancel RSVP action
2. **Waitlisted**: Full experiences where the user is queued on the waitlist, with waiting indicator and Leave Waitlist action
3. **Attended**: Completed micro-group meetups the user attended, with trigger for private Post-Experience Choices
4. **Past**: Concluded or expired experiences archived for reference

---

## I. Experience Room

### Before the Activity
- Experience information page with details
- Moderated participant group space (where appropriate)
- **Guided prompts** to ease interaction:
  - *"What is something you have always wanted to try?"*
  - *"Which place would you love to visit?"*
  - *"What makes a weekend enjoyable?"*
  - *"What hobby would you like to learn?"*
  - *"Would you prefer a spontaneous adventure or a planned day?"*

### During the Activity
- The experience takes place in person or online
- No live location tracking
- No anonymous video chat

### After the Activity
- Experience marked as completed
- Triggers the **Post-Experience Connection Selection** flow

---

## J. Post-Experience Connection Selection (Phase 3 Implemented)

> [!IMPORTANT]
> This is the core differentiating feature of MELSAVA. Every aspect of this flow protects privacy, guarantees non-negotiable mutual consent, and prevents unrequited or accidental romantic connections.

### 1. Host Attendance Confirmation Workflow
1. Once an experience concludes, the experience host opens the **Experience Hub** or taps the **Attendance** button from **My Circles**.
2. The host reviews the verified list of joined participants via `get_host_joined_participants`.
3. The host marks who actually attended (with "Select All" / per-person toggles).
4. Upon review, the host submits confirmation via atomic `complete_experience_and_mark_attendance` RPC:
   - Experience status transitions to `completed`.
   - Selected members have their membership status updated to `attended`.
   - Waitlisted, cancelled, or unjoined users cannot be marked attended.
   - Non-hosts and normal members cannot mark attendance or alter membership records.

### 2. Participant Eligibility & Attendee Discovery
1. A participant navigates to **My Circles → Attended** and selects **Choose Connections**.
2. The system checks server gating status via `fetch_reconnect_submission_status`:
   - Must be authenticated.
   - Experience must be marked `completed`.
   - User must have confirmed `attended` status.
   - Resubmissions are rejected if the user already submitted (`post_experience_submissions` table).
3. Eligible peer discovery via `fetch_eligible_reconnect_attendees`:
   - Returns only fellow attendees who attended the exact same completed experience.
   - Excludes the caller themselves.
   - Excludes blocked relationships in either direction and suspended accounts.
   - Zero sensitive PII exposed (only display name, avatar, bio, and shared experience context).
   - Other users' private choices are NEVER returned or visible.

### 3. Private Connection Choices Screen (`PostExperienceChoiceScreen`)
- **Heading:** *"Who would you like to meet again?"*
- **Supporting Text:** *"Your choices are private. A connection happens only when both people choose each other with compatible intentions."*
- **Default State:** Defaults to `No Connection` for every attendee (no pre-selected positive choices; no assumed romantic intent).
- **Available Intentions:**
  1. **Friendship** (`friendship`) — Connect as friends
  2. **Activity Partner** (`activity_partner`) — Connect for future activities
  3. **Explore Dating** (`explore_dating`) — Explore a romantic connection
  4. **No Connection** (`no_connection`) — Pass privately without notification
- **Pre-Submission Confirmation Sheet:** Users review their choices before final submission, with a clear privacy reminder.

### 4. Exact Matching Consent Rule
Connections are processed server-side via `submit_post_experience_choices`:
- **Friendship + Friendship** → Mutual Friendship Connection
- **Activity Partner + Activity Partner** → Mutual Activity Partner Connection
- **Explore Dating + Explore Dating** → Mutual Dating Connection
- **Friendship + Explore Dating** → **NO CONNECTION** (strictly no auto-promotion to dating)
- **Activity Partner + Explore Dating** → **NO CONNECTION**
- **No Connection + Any Option** → **NO CONNECTION**
- **One-Sided Selections** → **NO CONNECTION** (silent, zero rejection feedback)

### 5. Atomic Connection & Conversation Creation
When an exact match is confirmed:
1. Canonical row inserted into `public.connections` (`user_a_id < user_b_id`).
2. Unique conversation record inserted into `public.conversations`.
3. Bidirectional membership records added to `public.conversation_members`.
4. In-app notifications generated for both users in `public.app_notifications`.
5. Idempotent submission logged in `public.post_experience_submissions`.
6. Only the caller's own mutual connections are returned to Flutter.

### 6. Screen States & Celebratory Feedback
- **Loading:** Shimmer / spinner loading participants.
- **Available Attendees:** Independent participant cards with intention selector chips.
- **Submitting:** Choice controls disabled with progress indicator.
- **Submitted Without Match:** *"Your choices have been submitted privately. When another person's choice is mutual and compatible, you'll be notified."*
- **Mutual Match Unlocked:** Triggers the botanical `MutualMatchCelebrationDialog` displaying the matched peer's photo, name, and connection type.
- **Already Submitted:** Informative screen preventing resubmission.
- **Not Eligible:** Clear message that only confirmed attendees may reconnect.
- **Experience Not Completed:** Informs user to wait until the host confirms completion.
- **Empty State:** When no other attendees are eligible to reconnect.
- **Network Error:** Retry banner preserving selected choices.

---

## K. Connections (Phase 4 Implemented)

### Connections Screen (`ConnectionsScreen`)
**Heading:** *"Good moments can become great connections."*

### Display & Architecture
- Live Supabase-backed list powered by `get_user_connections` RPC and Riverpod `userConnectionsProvider`.
- Excludes blocked users and suspended accounts.
- Zero fake compatibility scores and zero artificial online presence dots.
- For each mutual connection:
  - Partner profile photo with initials fallback (`AppSmartImage`)
  - Full display name & bio snippet
  - Connection type badge (`Friends`, `Activity`, `Dates`)
  - Originating experience context ("Weekend Trek to Mukutmanipur")
  - Genuine last message preview & time-ago timestamp
  - Direct **Message** CTA opening the conversation thread
- **Filter Tabs**:
  - Filter by `All`, `Friends`, `Activity`, and `Dates` with accurate real-time count badges.
- **Cosmic Orbit View (`OrbitalConnectionsView`)**:
  - Interactive celestial visualization clustering mutual connections by relationship category with direct private chat access.
- **States**:
  - **Loading**: Styled shimmer indicators.
  - **Empty State**: Guided prompt explaining how to unlock connections by attending meetups.
  - **Error State**: Non-blocking retry button.

---

## L. Messaging & Realtime Chat (Phase 4 Implemented)

### Conversation List (`InboxScreen`)
- Live Supabase-backed thread list powered by `get_user_inbox_threads` RPC and Riverpod `inboxThreadsProvider`.
- Active threads where caller is a confirmed member, connection is active, and no blocks exist.
- Each thread card renders:
  - Partner name and profile avatar
  - Connection category chip
  - Originating experience title
  - Real last message snippet and server-computed timestamp
  - Genuine unread count badge (`is_read = FALSE` on incoming messages)
- **Recent Connections Carousel**: Top scrollable row of mutual connections for instant 1-tap chat opening.
- **States**:
  - Full support for Loading, Error with Retry, and Empty ("No conversations yet") states in Light and Dark themes.

### Conversation Screen (`ConversationScreen`)
- **Originating Experience Context Banner**: Dynamic top banner confirming the shared experience ("You both reconnected after Sunset Photography Walk. Keep chats respectful and genuine.").
- **Realtime Delivery**: Subscribes to Supabase Realtime channel (`postgres_changes` on `messages` filtered by `conversation_id`).
- **Instant Optimistic UI**: Appends sent messages immediately with pending indicators; deduplicates upon server echo.
- **Draft Preservation on Failure**: If network fails, the user's message draft remains in the input field with a retry SnackBar. Max 1,000 characters enforced client- and server-side.
- **Read Receipts**:
  - Outgoing messages display:
    - Single check icon (`Icons.check_rounded`) when delivered (`is_read = FALSE`).
    - Double check icon (`Icons.done_all_rounded` in `AppColors.mintAccent`) when read by the partner (`is_read = TRUE`).
  - Incoming messages automatically invoke `mark_conversation_read` upon screen load or realtime arrival, updating thread unread counts across the app.
- **Empty State & Guided Icebreakers**:
  - When opening a new connection thread with 0 messages, displays peer avatar, friendly reconnection greeting, and 3 actionable icebreaker buttons ("Hey! It was great connecting at the meetup! 👋", etc.).
- **In-Chat Safety Controls**:
  - **Report User**: Categorized reporting dialog (`ReportDialog`) submitting to MELSAVA safety team via `reportUser` RPC.
  - **Block User**: Destructive confirmation dialog (`ConfirmationDialog`) executing atomic `blockUser` RPC, invalidating connections and inbox providers, and popping the chat screen immediately.

---

### MVP Boundaries
- Text only (no voice, video, or media)
- No disappearing messages

---

## M. Profile Management, Safety & Account Settings

### Profile Tab (`ProfileScreen`)
Displays real authenticated user details:
- **Profile Photo**: Rendered via `AppSmartImage`, with green verified badge rendered strictly if `user.isVerified == true`.
- **Display Name & Location**: Actual display name (never hard-coded demo fallbacks like "Sneha") and selected city.
- **Bio**: Genuine bio text or friendly prompt to add one.
- **Real Statistics**: Displays real attended/upcoming experiences joined count and real mutual connections count. Fake follower metrics ("12 Followers") are completely omitted.
- **Interests & Passions**: Real selected interests chips.
- **Safety Card**: Direct one-tap navigation to the 10 Community Guidelines.

### Edit Profile Sheet (`EditProfileSheet`)
Full-featured interactive sheet allowing real-time edits:
- **Custom Photo Upload**: Select from device gallery or camera via `ImagePicker`, uploaded directly to Supabase Storage `avatars` bucket (`avatars/${userId}/...`).
- **Display Name**: Validated to between 2 and 50 characters.
- **Bio**: Short introduction text.
- **Location & City**: Worldwide city selector.
- **Intentions**: Primary connection intention (Friendship, Exploring Dating, Activity Partner).
- **Interests**: Multiselect interest tags.
- **Atomic Persistence**: Persisted atomically via `update_user_profile` RPC, updating `profiles`, `profile_interests`, `profile_intentions`, and `profile_private`. Retains input and provides error feedback on failure.

### Block Management (`BlockedProfilesScreen`)
- Accessible from Settings → Privacy & Safety → Blocked Profiles.
- Powered by `get_blocked_users()` RPC and `blockedUsersProvider`.
- Displays real list of blocked users with avatars, names, and blocked dates.
- Provides immediate "Unblock" action with confirmation dialog, cache invalidation, and real-time reflection across Connections and Inbox.

### Confidential Reporting System (`ReportDialog`)
- Modal report dialog accessible from conversation menus, connection profiles, and experience participant cards.
- 9 Canonical Report Categories:
  1. *Inappropriate or offensive behavior*
  2. *Harassment or unwanted contact*
  3. *Hate speech or discrimination*
  4. *Commercial solicitation or spam*
  5. *Misrepresentation or fake profile*
  6. *Safety concern at an activity*
  7. *No-show or unexcused absence*
  8. *Non-consensual contact or privacy violation*
  9. *Other community guideline concern*
- Enforces 500-character max limit on descriptions with counter.
- Strictly confidential storage via `submit_user_report` RPC.
- Asynchronous submission state with loading spinner; never closes prematurely on network failure.

### Community Guidelines (`CommunityGuidelinesScreen`)
- Dedicated screen detailing MELSAVA's 10 Core Guidelines:
  1. Authentic Identity
  2. Public Venues Only
  3. Zero Tolerance for Harassment
  4. Explicit Consent & Boundaries
  5. Punctuality & RSVP Etiquette
  6. Non-Commercial Gathering
  7. Privacy & Discretion
  8. Substance & Alcohol Moderation
  9. Inclusion & Kindness
  10. Proactive Safety & Reporting
- Accessible from Settings, Profile, and Report dialogs.

### Privacy & Safety Controls
- Stored in `public.profile_private.privacy_settings` JSONB via `get_privacy_settings` / `update_privacy_settings` RPCs:
  - **Public Activity Radar**: Attendee discovery visibility on event radar.
  - **Incognito Ghost Mode**: Complete discovery browsing concealment.
  - **Display Active City**: Home city badge toggle on member profile.

### Basic Moderation Console (`ModerationScreen`)
- Restricted to verified community moderators (`is_moderator()` / `isModeratorProvider`).
- Filter reports by status: Pending, Reviewed, Resolved, Dismissed, All.
- Moderator Actions:
  - **Dismiss**: Resolves report as dismissed without penalty.
  - **Issue Warning**: Records formal warning in `moderation_actions` audit log.
  - **Suspend Account**: Sets `profiles.is_suspended = TRUE` and records action, revoking access to all conversations and circles.

### Account Deletion & Deactivation
- **Temporary Deactivation**: Sets `is_deactivated = TRUE` via atomic `deactivate_user_account` RPC, hides profile and activities, preserves connections for return.
- **Permanent Account Deletion**:
  - Requires user to explicitly type `'DELETE'` in a dedicated confirmation dialog with progress spinner.
  - Executed exclusively via `delete-account` Supabase Edge Function (Deno) with server-side recent re-authentication verification (<15 minutes).
  - Purges user avatar from Supabase Storage `avatars` bucket.
  - Cascades profile foreign keys (blocks, reports, choices, connections, conversations).
  - Deletes user from Supabase Auth via Admin API (`adminClient.auth.admin.deleteUser(userId)`).
  - Never deletes `profiles` record alone on failure; rethrows clear errors while keeping user session intact until confirmed server completion.

---

## Navigation Structure

### Bottom Navigation Bar (5 Tabs)

| Tab | Icon | Screen |
|---|---|---|
| Discover | Compass | Main discovery feed |
| Experiences | Calendar | Browse & manage experiences |
| Connections | People | View mutual connections |
| Inbox | Chat bubble | Conversations |
| Profile | Person | Profile & settings |

The navigation bar is **persistent** across all main screens.

---

## State Handling

Every screen handles four states consistently:

| State | Behaviour |
|---|---|
| **Loading** | Loading indicator (spinner or skeleton) |
| **Empty** | Friendly empty-state message with suggested action |
| **Error** | Clear error message with retry option |
| **Success** | Content displayed normally |

### Empty State Copy Examples

| Screen | Copy |
|---|---|
| No Experiences | *"Nothing nearby just yet. Explore another category or check back soon."* |
| No Connections | *"Your next connection could start with your next experience."* |
| No Messages | *"Enjoyed meeting someone? Your mutual connections will appear here."* |

---

*This document describes the intended complete user journey for MELSAVA MVP. Features marked for later phases are noted in [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md).*
