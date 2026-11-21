# MELSAVA — Phase 6 Multi-Account Testing & Production Hardening Report

**Project**: MELSAVA Flutter Application  
**Execution Date**: November 2026  
**Environment**: Live Supabase Backend (`luxxwitcptqesmnqruld.supabase.co`) & Android Emulator (`emulator-5554`, API 36)  
**Status**: Completed & Verified  

---

## 1. Executive Summary

Phase 6 ("Multi-Account Testing & Production Hardening") subjected MELSAVA to comprehensive real-world multi-account verification against the live Supabase production-grade backend, resolved critical database query performance bottlenecks, introduced custom URL deep link navigation for password resets and magic links, and implemented zero-cost offline resilience for experience browsing.

All seven test scenarios executed with real authenticated accounts and actual database records on PostgreSQL. Zero hard-coded mocks or synthetic workarounds were used.

---

## 2. Testing Accounts & Roles

Testing utilized distinct accounts with specific roles to verify complete multi-account isolation and interaction:

| Account | Email / Identifier | User ID | Role |
|---|---|---|---|
| **Host** | `admin@melsava.com` | `e2a537ea-626a-4dbe-ab5e-e462c191a629` | Verified Experience Host & Platform Admin |
| **Attendee A** | `priya@melsava.com` | `5cbf239f-7ec4-4531-bc6e-21ef65b9fc07` | Experience Attendee & Verified Member ("Priya Patel") |
| **Attendee B** | `znom926@gmail.com` | `ee3fa775-fe0e-450f-a367-e9fa6506dbca` | Experience Attendee & Mutual Connection ("Subrata Ghosh") |
| **Moderator** | `admin@melsava.com` | `e2a537ea-626a-4dbe-ab5e-e462c191a629` | Platform Moderator (`public.moderators`) |
| **Disposable** | `disposable_beta_1732152800@melsava.com` | Dynamic UUID | Ephemeral user for permanent account deletion testing |

---

## 3. Real-World Multi-Account Verification Matrix

### Scenario 1: Authentication & Verification
- **Goal**: Verify authentic session generation, JWT issuance, route permissions, and adult eligibility protection.
- **Actions Tested**:
  1. Signed in as Host (`admin@melsava.com`) via Supabase Auth API: Access token received, profile retrieved.
  2. Signed in as Attendee A (`priya@melsava.com`): Access token received, profile retrieved.
  3. Signed in as Attendee B (`znom926@gmail.com`): Access token received, profile retrieved.
  4. Tested invalid credentials and under-18 registration prevention in `AuthValidators`.
- **Observed Result**: All three accounts successfully authenticated; invalid credentials rejected with sanitized error messages.
- **Status**: **PASS**

### Scenario 2: Profile & Preference Management
- **Goal**: Test atomic profile updates against canonical database dictionaries, verify private preference persistence, and confirm zero cross-account data leakage.
- **Actions Tested**:
  1. Invoked `update_user_profile` RPC as Attendee A (`priya@melsava.com`).
  2. Updated Bio: `"Passionate photographer, coffee explorer, and art lover."`
  3. Associated canonical interests from `public.interests`: `['Art', 'Photography']`.
  4. Associated canonical primary & secondary intentions from `public.intentions`: `'Genuine friendship'` (Primary), `'Activity partner'` (Secondary).
  5. Updated discovery preferences in `public.profile_private`: Min age 21, Max age 40, Max distance 25km.
  6. Verified that Attendee B's profile and private settings remained completely unmodified and inaccessible to Attendee A.
- **Observed Result**: Profile and private preferences updated atomically in one transaction. Canonical constraints enforced.
- **Status**: **PASS**

### Scenario 3: Experience Joining, Capacity Limits & FIFO Waitlist
- **Goal**: Verify atomic row locking (`FOR UPDATE`), strict capacity enforcement, and FIFO waitlist auto-promotion.
- **Actions Tested**:
  1. Host created test experience: `"Kolkata Street Photography & Chai Walk"` with strict capacity limit = 1.
  2. Attendee A (`priya@melsava.com`) invoked `join_experience`: Membership assigned status `joined` (1/1 spots filled).
  3. Attendee B (`znom926@gmail.com`) invoked `join_experience`: Capacity exhausted; assigned status `waitlisted` (FIFO queue position 1).
  4. Verified experience count aggregates: 1 joined, 1 waitlisted.
  5. Attendee A invoked `cancel_experience_membership`.
  6. Inspected database state: Attendee A marked `cancelled`; Attendee B automatically promoted from `waitlisted` to `joined` with zero host intervention.
- **Observed Result**: Zero overbooking occurred; FIFO queue order was strictly honored upon cancellation.
- **Status**: **PASS**

### Scenario 4: Attendance Confirmation, Private Mutual Choice & Connection Creation
- **Goal**: Verify host attendance completion, strict exact intention matching, and zero-leakage connection creation.
- **Actions Tested**:
  1. Host called `complete_experience_and_mark_attendance` confirming attendance for both Attendee A and Attendee B.
  2. Experience status transitioned to `completed`.
  3. Attendee A submitted post-experience choice via `submit_post_experience_choices`: Selected Attendee B with choice type `'friendship'`.
  4. Verified database state: At this stage, NO connection exists; Attendee B cannot view Attendee A's choice.
  5. Attendee B submitted post-experience choice: Selected Attendee A with choice type `'friendship'`.
  6. Server-side matching algorithm executed atomically: Detected exact match (`'friendship'` == `'friendship'`).
  7. Inspected database:
     - Canonical record created in `public.connections` (`user_a_id < user_b_id`).
     - Real conversation created in `public.conversations`.
     - Two membership rows created in `public.conversation_members`.
     - In-app match notifications dispatched to `public.app_notifications`.
- **Observed Result**: Connections and conversations created only upon verified bilateral agreement; zero rejection notifications generated.
- **Status**: **PASS**

### Scenario 5: Connections, Messaging & Read Receipts
- **Goal**: Test bilateral conversation security, realtime messaging, unread counts, and bidirectional blocking.
- **Actions Tested**:
  1. Attendee B sent real message to Attendee A via `send_conversation_message`:
     `"Hey Priya! Great meeting you at the photography walk. Loved your perspective on the colonial architecture!"`
  2. Verified message row inserted in `public.messages` with `sender_id = Attendee B` and `is_read = false`.
  3. Inquired inbox for Attendee A via `get_user_inbox_threads`: Unread count incremented to 1.
  4. Attendee A marked thread read via `mark_conversation_read`: `is_read` flipped to `true`.
  5. Tested bilateral safety blocking: When Attendee A blocks Attendee B, `can_access_conversation` immediately returns `false` for both parties, prohibiting further messages or reading.
- **Observed Result**: Realtime messaging works with guaranteed sender stamping; blocking immediately isolates both participants.
- **Status**: **PASS**

### Scenario 6: Safety, Blocking & Content Reporting
- **Goal**: Verify confidential reporting with canonical reason validation and anti-spam throttling.
- **Actions Tested**:
  1. Attendee A reported an abusive profile via `submit_user_report` with canonical reason: `'Inappropriate or offensive behavior'`.
  2. Report was securely stored with confidential reporter ID.
  3. Immediate duplicate submission was blocked by server-side 1-hour anti-spam throttle.
  4. Moderator logged in (`admin@melsava.com`), queried `get_moderation_reports`, and viewed the pending report in the moderation queue.
- **Observed Result**: Reports are strictly confidential and protected from brute-force spamming.
- **Status**: **PASS**

### Scenario 7: Disposable Account Permanent Deletion
- **Goal**: Verify irreversible cascade deletion of all personal data, profiles, and auth records.
- **Actions Tested**:
  1. Created disposable test user (`disposable_beta_*@melsava.com`).
  2. Populated associated profile, preferences, and test data.
  3. Invoked Edge Function / Admin API cascade purge.
  4. Queried `auth.users`, `public.profiles`, and `public.profile_private`.
- **Observed Result**: All database rows completely erased across all tables. Zero orphaned records left behind.
- **Status**: **PASS**

---

## 4. Query Performance & EXPLAIN ANALYZE

### Benchmark Summary (Migration 018 Optimization)
Measurements conducted on PostgreSQL 15 via `EXPLAIN (ANALYZE, BUFFERS)`:

| Operation | Query / Target | Before Indexing | After Indexing | Speedup |
|---|---|---|---|---|
| **Messages Pagination** | `SELECT * FROM messages WHERE conversation_id = $1 ORDER BY created_at DESC LIMIT 50` | 1.967 ms | 0.058 ms | **~33x faster** |
| **Unread Count** | `SELECT count(*) FROM messages WHERE conversation_id = $1 AND sender_id != $2 AND is_read = false` | 1.450 ms | 0.038 ms | **~38x faster** |
| **Upcoming Feed** | `SELECT * FROM experiences WHERE status = 'published' AND starts_at >= now() ORDER BY starts_at ASC` | 0.812 ms | 0.092 ms | **~8.8x faster** |
| **Waitlist FIFO** | `SELECT * FROM experience_members WHERE experience_id = $1 AND status = 'waitlisted' ORDER BY joined_at ASC` | 0.640 ms | 0.045 ms | **~14x faster** |

Full empirical query execution plans and buffer statistics are documented in [PERFORMANCE_REPORT.md](file:///c:/Users/sulat/Desktop/projects/flutter_workspace/dating_app/PERFORMANCE_REPORT.md).

---

## 5. Deep Links & Auth Callbacks

Custom URL scheme deep linking was configured across Android, iOS, and Flutter GoRouter:
- **Custom Scheme**: `melsava://`
- **Supported Paths**:
  - `melsava://auth-callback`: Email verification and magic link session completion.
  - `melsava://reset-password`: In-app password update screen (`ResetPasswordScreen`).
- **Implementation**:
  - `android/app/src/main/AndroidManifest.xml`: Registered `<intent-filter>` for `melsava` scheme.
  - `ios/Runner/Info.plist`: Registered `CFBundleURLTypes` with `CFBundleURLSchemes = ['melsava']`.
  - `lib/app/app_router.dart`: Added `/auth-callback` and `/reset-password` routes; updated `computeRedirect` to prevent authentication redirection loops.
  - `lib/features/auth/presentation/reset_password_screen.dart`: Created full responsive UI supporting dark/light mode, input validation, and password update via `updatePassword`.

---

## 6. Offline Resilience & Experience Caching

To ensure smooth operation on intermittent network connections without recurring paid services:
- **Local Cache**: Upcoming experiences cached in local device storage (`SharedPreferences`) with timestamp.
- **Offline Notice Bar**: Built `OfflineNoticeBar` widget displaying `"Offline Mode • Cached at HH:mm"` with a one-tap `"Retry"` action.
- **Failover Logic**: `ExperiencesRepository.getPublishedExperiences()` returns cached data upon network errors, setting `isServingCachedOfflineData = true`.
- **Mutation Safety**: All write actions (joining, cancelling, post-experience choices, reporting) fail gracefully with clear offline dialogs rather than corrupting state.

---

## 7. Automated Test Suite Results

```text
00:15 +88: All tests passed!
```

- **Total Test Files**: 8 test suites
- **Total Unit & Widget Tests**: 88 passing tests
- **Static Analysis**: `flutter analyze` — 0 issues found
- **Compilation**: Debug APK built successfully (`app-debug.apk`, 46.1s)

---

## 8. Verification Conclusion

Phase 6 production hardening and multi-account verification are **100% complete**. The MELSAVA platform is verified as stable, performant, secure, and ready for closed beta staging.
