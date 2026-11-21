# MELSAVA — Messaging Security & Trust & Safety Architecture

## Overview
MELSAVA adopts the standard social and dating application messaging architecture (as utilized by Tinder, Bumble, Hinge, and Instagram Direct). This architecture balances **robust user privacy**, **transport security**, **high-performance realtime delivery**, and **effective Trust & Safety moderation**.

---

## 1. Security Architecture Principles

### A. Transport Layer Security (TLS 1.3)
All communications between MELSAVA client applications and backend Supabase endpoints are strictly encrypted in transit using **TLS 1.3** across both HTTPS REST APIs and secure WebSockets (WSS).
- Protects users against eavesdropping, interception, packet sniffing, and Man-in-the-Middle (MITM) attacks on public Wi-Fi or cellular networks.

### B. PostgreSQL Row Level Security (RLS) & Access Control
Database-level security is enforced at the database layer via PostgreSQL Row Level Security (RLS) and Security Definer RPCs:
1. **Conversation Membership Boundary**: A user can only fetch, stream, or insert messages if their authenticated user ID (`auth.uid()`) is an active member of `conversation_members` for that specific `conversation_id`.
2. **Third-Party Isolation**: Arbitrary users or external callers cannot access, query, or enumerate messages from conversations they do not belong to.
3. **RPC Validation (`send_conversation_message`)**:
   - Enforces authentication checks.
   - Trims and sanitizes message text.
   - Verifies participant mutual attendance/connection status.
   - Automatically bumps `conversations.last_message_at` and unread counters.

### C. Trust & Safety Moderation & Abuse Prevention
Dating and social apps have a critical duty of care to protect members from stalking, harassment, explicit abuse, scams, and threats:
1. **Moderation Audit Capability**: When a user files a report against another member, the MELSAVA Trust & Safety team can review reported message logs to verify community guideline violations and take prompt protective actions (warnings, suspensions, or bans).
2. **Confidential Reporting**: The reported user is never notified of the reporter's identity.
3. **One-Tap Blocking**: When a user blocks a partner, communication is immediately severed, conversation access is revoked, and future experience group pairings are prevented.

---

## 2. User Experience Benefits
1. **Clean Bubble Layout**: Clean timestamps (`10:28 AM`) and read receipt checkmarks (`✓` / `✓✓`) without confusing lock icons or `[Encrypted message]` placeholders.
2. **Instant Multi-Device Sync**: Messages load instantly from the server without local key-exchange handshakes, session state desynchronization, or unreadable message errors when switching phones.
3. **Streamlined UI**: Header shows the connected peer name and status cleanly without unnecessary 60-digit safety numbers or QR verification screens.
