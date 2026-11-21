# MELSAVA — Community Safety, Moderation & Appeals Guide

## 1. Safety Architecture

MELSAVA utilizes a hybrid moderation architecture:
1. **Deterministic Pre-Publish Filters**: Automatic checks block obvious spam, duplicate activities, external payment links (`paypal.me`, `cash.app`, `t.me/`), and rate limits.
2. **Confidential Peer Reporting**: Any member can report an activity, profile, review, or chat message.
3. **Internal Moderation Console**: Authorized community guides and administrators review flags, approve pending activities, issue formal warnings, suspend accounts, and resolve appeals.

---

## 2. Canonical Report Reasons (9 Core Violation Categories)

Every report in MELSAVA maps to one of the 9 canonical reasons:

1. **Harassment / Bullying**: Unwanted pressure, insulting language, or threatening behavior.
2. **Inappropriate Content**: Explicit imagery, sexualized remarks, or offensive text.
3. **Spam / Promotion**: External sales, commercial solicitation, cryptocurrency, or unsolicited product marketing.
4. **Scam / Fraud**: Requests for wire transfers, gift cards, off-platform cash transfers, or fake activities.
5. **Impersonation**: Pretending to be someone else or creating a fake profile.
6. **Underage User**: Account holder is suspected of being younger than the mandatory age of 18.
7. **Host No-Show**: The organizer did not attend or abandoned the circle without warning.
8. **Safety Concern**: Physical danger, non-public venue location, or feeling unsafe during an event.
9. **Other**: Any guideline breach not covered above, requiring specific explanatory details.

---

## 3. Moderator Actions & Due Process

| Action | Impact | Client Effect |
|---|---|---|
| **Dismiss** | Report resolved without penalty. | None. Reporter is informed of review completion. |
| **Warning** | Formal logged warning in `moderation_actions`. | Member receives a warning banner upon opening the app. |
| **Activity Removal** | Sets `moderation_status = 'removed'`. | Activity disappears from Discovery; members are notified. |
| **Activity Approval** | Sets `moderation_status = 'approved'`. | Activity published to Discover immediately. |
| **Account Suspension** | Sets `profiles.is_suspended = true`. | Session revoked; member redirected to `/welcome` with suspension banner. |

---

## 4. Appeals Workflow

1. A suspended member or organizer whose circle was removed can submit a formal appeal detailing their perspective.
2. Appeals appear in the **Appeals Tab** of the Moderation Console (`/moderation`).
3. The moderator reviews:
   - Original action reason and evidence.
   - Member's written explanation.
4. If **Approve & Restore**:
   - `resolve_moderation_appeal(appeal_id, 'approved', notes)` restores member profile access or re-publishes the circle.
5. If **Reject**:
   - `resolve_moderation_appeal(appeal_id, 'rejected', notes)` upholds the penalty.
