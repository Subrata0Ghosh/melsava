# MELSAVA — Community Trust, Reputation, Reviews & Anti-Spam System

## 1. Core Product & Architectural Principle

> **"New users must get a fair opportunity to create activities, meet people, and build their reputation. Never make popularity or an established history a requirement for joining the community."**

MELSAVA is built around authentic, in-person human micro-groups. Unlike platforms dominated by high-follower influencers or commercial businesses, MELSAVA treats trust as a dynamic reflection of real-world consistency, safety compliance, and verified attendee feedback.

---

## 2. Architecture & Components

```
┌────────────────────────────────────────────────────────────────────────┐
│                        MELSAVA FLUTTER CLIENT                          │
├──────────────────┬──────────────────┬─────────────────┬────────────────┤
│ Create a Circle  │ Fair Discovery   │ Host Trust Card │ Verified Review│
│ (Max 10 / Day 3) │ (Cold-Start Boost│ (No Fake Stars/ │ (Post-Meetup   │
│                  │  & Area Weight)  │  Threshold 5)   │  Attended Only)│
└────────┬─────────┴────────┬─────────┴────────┬────────┴────────┬───────┘
         │                  │                  │                 │
         ▼                  ▼                  ▼                 ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        SUPABASE POSTGRESQL / RLS                       │
├────────────────────────────────────────────────────────────────────────┤
│ • experiences (moderation_status, area, price_amount, is_recurring)    │
│ • experience_reviews (1 per attendee, non-self, 5 structured questions)│
│ • user_reputation (levels: new_host, active, reliable, trusted)        │
│ • moderation_appeals (appeal logging & resolution)                     │
│ • moderation_actions & reports (9 canonical violation reasons)         │
├────────────────────────────────────────────────────────────────────────┤
│ RPCs: create_user_experience | submit_experience_review                │
│       recalculate_user_reputation | get_host_reputation               │
│       moderator_moderate_experience | resolve_moderation_appeal         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Fair Opportunities for New Hosts (Anti-Popularity Bias)

1. **Cold-Start Discovery Boost**:
   - New hosts (`is_new_host = true`) receive a +40 discovery weighting score in `applyFiltersAndRanking` and in `fetchNewInYourArea`.
   - A dedicated *"New in your area"* shelf surfaces first-time circles directly on the Discover page.
2. **Initial Capacity Guardrail**:
   - First-time hosts have a server-enforced capacity limit (max 10 participants).
   - This prevents chaotic crowds and ensures intimate, high-quality, safe circles.
3. **No Fake Badges or Zero Stars**:
   - New hosts are clearly and respectfully badged as **"New Host"**.
   - Average ratings display **"Not yet rated"** until the host completes circles and gathers **at least 5 verified reviews**.
   - Hosts without reviews are never shown 0.0 or empty stars that look like poor performance.

---

## 4. Verified Post-Experience Reviews

- **Eligibility**:
  - Only confirmed attendees with `status = 'attended'` can submit a review.
  - Review window opens only after the experience is marked `completed`.
  - Self-reviews are strictly rejected (`reviewer_id != host_id`).
  - Exactly one review allowed per attendee per activity.
- **Structured Assessment (5 Core Safety & Quality Booleans)**:
  1. *Was the experience accurately described?* (`was_as_described`)
  2. *Was the host welcoming, punctual, and respectful?* (`was_host_respectful`)
  3. *Did the host arrive on time and guide the group?* (`did_host_arrive`)
  4. *Did you feel safe, comfortable, and included throughout?* (`felt_safe_comfortable`)
  5. *Would you join another circle hosted by this member?* (`would_join_again`)
- **Rating**: 1 to 5 stars + optional constructive feedback.

---

## 5. Reputation Levels & Lifecycle

| Level | Badge | Minimum Circles | Minimum Reviews | Min Rating | Perks / Limits |
|---|---|---|---|---|---|
| **New Host** | 🌱 New Host | 0 | 0 | Not yet rated | Max 10 capacity, cold-start boost, max 3 circles/day |
| **Active Host** | 🌿 Active Host | 2 | 3 | -- | Max 16 capacity |
| **Reliable Host** | ⭐ Reliable Host | 5 | 5 | 4.2+ | Max 24 capacity |
| **Trusted Host** | 🛡️ Trusted Host | 10 | 10 | 4.7+ | Max 30 capacity, Priority Verified badge |

---

## 6. Anti-Spam & Automated Safety Heuristics

1. **Daily Rate Limits**: Max 3 circles created per 24 hours for new hosts.
2. **Duplicate Detection**: Blocks exact duplicate circle descriptions within 48 hours.
3. **External Payment / Scam Detection**: Descriptions containing keywords like `paypal.me`, `cash.app`, `t.me/`, or `wa.me/` are automatically held in `pending_review` for human moderation instead of crashing or going live unvetted.
4. **Suspension Restrictions**: Users under active moderation suspension or restricted activity creation are barred from publishing.

---

## 7. Appeals & Community Due Process

- Members subject to moderation warnings, circle removals, or suspensions can submit an appeal via `submit_moderation_appeal`.
- The Moderator Console includes a dedicated **Appeals Tab** allowing moderators to review the member's statement, inspect the original violation reason, and choose **Approve & Restore** or **Reject Appeal**.
