# MELSAVA — Performance & Query Optimization Report (Phase 6)

## Overview

This report provides empirical performance measurements and query plan analysis for core MELSAVA database operations executed against the live Supabase PostgreSQL engine (`db.luxxwitcptqesmnqruld.supabase.co`).

---

## 1. Index Audit & Foreign Key Coverage

### Initial Audit
An inspection of `pg_constraint` against `pg_index` uncovered 5 foreign keys lacking covering indexes:
- `profile_intentions(intention_id)`
- `moderation_actions(performed_by)`
- `post_experience_submissions(user_id)`
- `app_notifications(connection_id)`
- `app_notifications(experience_id)`

### Remediation in Migration 018
Migration `018_phase6_production_hardening.sql` added the required covering indexes:
1. `idx_profile_intentions_intention_id`
2. `idx_moderation_actions_performed_by`
3. `idx_post_experience_submissions_user_id`
4. `idx_app_notifications_connection_id`
5. `idx_app_notifications_experience_id`
6. `idx_messages_conversation_created` on `(conversation_id, created_at DESC)`
7. `idx_messages_unread` partial index on `(conversation_id, sender_id)` where `is_read = false`

---

## 2. PostgreSQL `EXPLAIN (ANALYZE, BUFFERS)` Measurements

### Query A: Discover Upcoming Published Experiences
- **Query**:
  ```sql
  SELECT id, title, description, cover_image_url, city, venue_name, venue_address,
         is_online, max_participants, status, starts_at, ends_at, duration_minutes
  FROM public.experiences
  WHERE status = 'published' AND starts_at > NOW()
  ORDER BY starts_at ASC
  LIMIT 20;
  ```
- **Plan**: `Index Scan using idx_experiences_published_starts_at on experiences`
- **Execution Time**: **1.984 ms** (Planning: 5.261 ms, Buffers: 2 hits)
- **Bottlenecks Found**: None. Single index scan satisfies both the status filter and chronological ordering.

### Query B: Participant Counts RPC Aggregation
- **Query**:
  ```sql
  SELECT experience_id,
         COUNT(*) FILTER (WHERE status = 'joined') AS joined_count,
         COUNT(*) FILTER (WHERE status = 'waitlisted') AS waitlisted_count
  FROM public.experience_members
  GROUP BY experience_id;
  ```
- **Plan**: `HashAggregate (Batches: 1, Memory Usage: 40kB)`
- **Execution Time**: **0.137 ms** (Planning: 1.926 ms, Buffers: 1 hit)
- **Bottlenecks Found**: None. Grouping runs in memory across active members.

### Query C: Conversation Messages Stream (Paging)
- **Query**:
  ```sql
  SELECT id, conversation_id, sender_id, content, is_read, created_at
  FROM public.messages
  WHERE conversation_id = '...'
  ORDER BY created_at DESC
  LIMIT 30;
  ```
- **Before Migration 018**:
  - Plan: `Bitmap Index Scan on idx_messages_conversation_id` followed by an in-memory `Sort (quicksort)`.
  - Execution Time: **1.967 ms**.
- **After Migration 018 (with `idx_messages_conversation_created`)**:
  - Plan: Direct index scan matching compound condition.
  - Execution Time: **0.058 ms - 0.154 ms** (**~13x-33x speedup**).

### Query D: User Connections Directory
- **Query**:
  ```sql
  SELECT c.id, c.user_a_id, c.user_b_id, c.connection_type, c.created_at,
         p.display_name, p.avatar_url
  FROM public.connections c
  JOIN public.profiles p ON p.id = (CASE WHEN c.user_a_id = $UID THEN c.user_b_id ELSE c.user_a_id END)
  WHERE c.user_a_id = $UID OR c.user_b_id = $UID
  ORDER BY c.created_at DESC;
  ```
- **Plan**: `BitmapOr on (idx_connections_user_a_id, idx_connections_user_b_id) -> Hash Join with profiles`
- **Execution Time**: **0.137 ms** (Planning: 0.785 ms, Buffers: 4 hits).

### Query E: Blocked Profiles Lookup
- **Query**:
  ```sql
  SELECT b.id, b.blocker_id, b.blocked_id, b.reason, b.created_at,
         p.display_name, p.avatar_url
  FROM public.blocks b
  JOIN public.profiles p ON p.id = b.blocked_id
  WHERE b.blocker_id = $UID
  ORDER BY b.created_at DESC;
  ```
- **Plan**: `Nested Loop with Memoize Index Scan using blocks_blocker_id_blocked_id_key`
- **Execution Time**: **0.075 ms**.

### Query F: Moderation Reports Feed
- **Query**:
  ```sql
  SELECT r.id, r.reporter_id, r.reported_user_id, r.reason, r.status, r.created_at,
         u.display_name AS reported_name
  FROM public.reports r
  LEFT JOIN public.profiles u ON u.id = r.reported_user_id
  ORDER BY r.created_at DESC
  LIMIT 50;
  ```
- **Plan**: `Hash Left Join with profiles -> Sort`
- **Execution Time**: **0.170 ms**.

---

## 3. Client-Side Performance & Network Footprint

1. **Client-Side Image Caching**:
   - `cached_network_image: ^3.4.1` is configured with placeholder shimmer and error fallback.
   - Profile avatars avoid unconstrained network re-fetches.
2. **Selective Query Projections**:
   - `experiences` feeds fetch only the public fields needed for card rendering (`id, title, description, cover_image_url, starts_at...`).
   - Profile hydration does NOT query or expose sensitive columns (`date_of_birth`, phone numbers, password hashes).
3. **Realtime Footprint**:
   - Postgres Realtime is scoped strictly to active conversations (`messages:conversation_id=eq.<id>`) and user-specific notifications (`app_notifications:user_id=eq.<id>`).
   - Realtime channels unsubscribe cleanly in widget `dispose()`.

---

## 4. Remaining Performance Risks & Mitigations

- **Risk**: As `experiences` grows beyond 10,000 rows, unbounded full-text searches could become slow.
  - **Mitigation**: A GIN index on `to_tsvector('english', title || ' ' || description)` can be introduced when experience volume warrants it.
- **Risk**: High-frequency concurrent RSVP traffic during popular drop events.
  - **Mitigation**: Handled atomically in `join_experience` via Postgres row-level locks (`SELECT ... FOR UPDATE` on `experiences`), eliminating race conditions and overbooking.
