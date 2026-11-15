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

## H. Join Experience Flow

### Steps
1. User taps **Join Experience**
2. System validates:
   - ✅ Account eligibility (profile complete, not suspended)
   - ✅ Available capacity (spots remaining)
   - ✅ Not already joined
   - ✅ No scheduling conflicts
3. RSVP record created
4. Confirmation screen displayed:
   - *"You're in! Here's what to know before the experience."*
   - Activity details summary
   - Date/time reminder
   - Venue or online instructions
5. Experience appears in **My Experiences**

### Additional Features
- **Cancel** — User can cancel their RSVP
- **Waitlist** — If capacity is full, user joins a waitlist
- **Reminders** — Notifications before the experience

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

## J. Post-Experience Connection Selection

> [!IMPORTANT]
> This is the core differentiating feature of MELSAVA. Every aspect of this flow must protect privacy and enforce mutual consent.

### Flow
1. After an experience is completed, each participant receives a notification
2. They open a **private selection page**
3. **Heading:** *"Who would you like to meet again?"*
4. **Explanation:** *"Your choices are private. A connection happens only when the feeling is mutual."*

### For Each Fellow Participant
The user sees:
- Participant's display name
- Profile photo
- Brief info

And selects one of:
| Choice | Meaning |
|---|---|
| **Friendship** | Connect as friends |
| **Activity Partner** | Connect for future activities |
| **Explore Dating** | Explore a romantic connection |
| **No Connection** | Pass (private, no consequence) |

### What Happens Next
- Selections are saved privately
- System processes each **pair** of participants:
  - **Mutual + Compatible** → Connection created, conversation opened
  - **One-sided** → Nothing happens
  - **Both pass** → Nothing happens
- **No rejection notifications** are ever sent
- **Selections are never exposed** to other users
- A friendship selection **never** automatically becomes a romantic match

### Technical Safeguards
- Operation is **atomic** and **transactional** on the server
- Duplicate submissions prevented
- Concurrent selections handled safely
- Blocked users excluded from selections

---

## K. Connections

### Connections Screen
**Heading:** *"Good moments can become great connections."*

### Display
- **New Connections** — Recently formed mutual connections (highlighted)
- **Existing Connections** — All active connections
- For each connection:
  - Profile photo and name
  - Connection type (Friend, Activity Partner, Dating)
  - Shared experience that brought them together
  - Connection date
  - **Message** button

### Features
- View the other person's approved profile details
- See shared experience history
- Start a conversation

---

## L. Messaging

### Conversation List (Inbox Tab)
- List of all active conversations
- Each shows:
  - Contact name and photo
  - Last message preview
  - Timestamp
  - Unread indicator

### Conversation Screen
- Real-time text messaging (via Supabase Realtime)
- Message bubbles with timestamps
- Read status (when practical)
- Connection context shown (which experience connected them)

### States
- **Loading** — Spinner while messages load
- **Empty** — *"Enjoyed meeting someone? Your mutual connections will appear here."*
- **Error** — Retry option with clear message

### Safety Features
- **Block User** — Blocks all further interaction
- **Report Conversation** — Flag inappropriate messages
- Users can **only** read conversations they are members of

### MVP Boundaries
- Text only (no voice, video, or media)
- No disappearing messages

---

## M. Profile Management

### Profile Tab
Displays and allows editing of:

| Section | Content |
|---|---|
| Photo | Profile photograph with edit option |
| Display Name | Editable name |
| Bio | Short introduction text |
| Interests | Selected interest tags |
| Intentions | Connection intentions (with primary) |
| Activities | Preferred activity categories |
| Location | Broad city/area |

### Settings & Controls
- **Edit Profile** — Modify any profile section
- **Privacy Controls** — What information is visible to others
- **Notification Settings** — Push notification preferences
- **Community Guidelines** — Review guidelines
- **Account Deletion** — Permanently delete account and data
- **Sign Out** — End current session

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
