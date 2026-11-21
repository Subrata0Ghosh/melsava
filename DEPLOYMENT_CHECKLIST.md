# MELSAVA — Production Deployment & Beta Pre-Flight Checklist

This checklist outlines the mandatory steps required to deploy the MELSAVA Flutter client, Supabase backend, and Edge Functions to staging or production for closed beta.

---

## 1. Environment & Configuration Variables

The client reads environment configuration via `flutter_dotenv` from `.env`. Never commit `.env` to source control.

| Variable | Description | Example / Required Format |
|---|---|---|
| `SUPABASE_URL` | Live Supabase project REST URL | `https://luxxwitcptqesmnqruld.supabase.co` |
| `SUPABASE_ANON_KEY` | Public anonymous client API key | `sb_publishable_...` or JWT anon key |

- [ ] Verify `.env` is present in the build root.
- [ ] Verify `.env` is listed in `.gitignore`.
- [ ] Verify `.env.example` contains sanitized dummy keys only.
- [ ] Ensure `SERVICE_ROLE` key is NEVER placed in `.env` or bundled in client assets.

---

## 2. Supabase Dashboard Configuration

In the [Supabase Dashboard](https://supabase.com/dashboard/project/luxxwitcptqesmnqruld/auth/url-configuration):

### Authentication & Redirect URLs
- [ ] **Site URL**: Configure your primary web landing domain or app link (e.g. `https://melsava.com`).
- [ ] **Redirect URLs (Deep Links)**: Add the following custom URL schemes:
  - `melsava://auth-callback` (for email verification and magic link logins)
  - `melsava://reset-password` (for in-app password recovery)
  - `http://localhost:3000/*` (if local web debugging is enabled)

### Auth Providers
- [ ] **Email Provider**: Enabled. Confirm email verification is enabled (`Confirm email: On`).
- [ ] **Google OAuth Provider**: Configured with Google Cloud Console OAuth 2.0 Web Client ID & Secret for Android / iOS token verification.

---

## 3. Database Migrations (PostgreSQL)

Execute migrations sequentially in the Supabase SQL Editor or via Supabase CLI (`supabase db push`):

1. `001_initial_schema.sql` — Base tables, enums, initial schema
2. `002_rls_policies.sql` — Core row-level security policies
3. `003_functions.sql` — Auth triggers and helper functions
4. `004_seed_data.sql` — Activity categories, interests, intentions
5. `005_onboarding_preferences_and_storage.sql` — Onboarding schema and storage bucket setup
6. `006_phase2_experiences_rls_and_rpc.sql` — Atomic join and cancel RPCs with `FOR UPDATE` locks
7. `007_fix_experience_members_recursion.sql` — RLS recursion resolution
8. `008_set_distinct_experience_covers.sql` — Experience visual covers
9. `009_phase3_attendance_and_mutual_choices.sql` — Host attendance, mutual matching RPC
10. `010_experience_circle_hub.sql` — Circle hub query optimization
11. `011_connections_and_inbox_rpcs.sql` — Connections and inbox thread resolvers
12. `012_phase3_hardening.sql` — Mutual choice row-locking and attendance end-time validation
13. `013_phase4_connections_and_realtime.sql` — Realtime messaging, unread counts, conversation RLS
14. `014_phase5_safety_and_profile.sql` — Moderation infrastructure, blocks, reports, atomic profile update
15. `015_phase4_security_hardening.sql` — Message table privilege revocation
16. `016_fix_inbox_and_rpc_signature.sql` — Inbox thread aggregation hardening
17. `017_phase5_security_and_integrity_hardening.sql` — Profile dictionary validation, privacy settings RPC
18. `018_phase6_production_hardening.sql` — Performance composite indexes and covering FKs

- [ ] All 18 migrations applied without errors.
- [ ] Verify 24 tables have `rowsecurity = true`.
- [ ] Verify all 37 database functions have explicit `SET search_path = public, pg_temp;`.

---

## 4. Storage Bucket Configuration

In [Supabase Storage](https://supabase.com/dashboard/project/luxxwitcptqesmnqruld/storage/buckets):

- [ ] Bucket **`avatars`** exists.
- [ ] Bucket is marked as **Public** (or uses signed URLs with RLS).
- [ ] Storage RLS Policy exists allowing users to insert/update objects under their own user folder:
  `bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text`.
- [ ] Storage RLS Policy exists allowing public read access to all avatars.

---

## 5. Supabase Edge Functions Deployment

Deploy serverless edge functions using the Supabase CLI:

```bash
supabase functions deploy delete-account --project-ref luxxwitcptqesmnqruld
```

- [ ] Deploy `delete-account` edge function.
- [ ] Confirm environment secrets are set on Supabase Edge Functions:
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY` (used solely within edge function for `auth.admin.deleteUser`)
- [ ] Test health check / pre-flight on `delete-account`.

---

## 6. Android Release Configuration

- [ ] Package name configured: `com.technorchid.melsava`.
- [ ] `AndroidManifest.xml` contains custom deep link intent filters:
  ```xml
  <intent-filter android:autoVerify="true">
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="melsava" android:host="auth-callback" />
      <data android:scheme="melsava" android:host="reset-password" />
  </intent-filter>
  ```
- [ ] Keystore and release signing configured in `android/key.properties` and `android/app/build.gradle`.
- [ ] Min SDK version set to at least 21 (MELSAVA uses API 24+ recommended).
- [ ] Build release App Bundle:
  ```bash
  flutter build appbundle --release
  ```

---

## 7. iOS Release Configuration

- [ ] Bundle Identifier configured.
- [ ] `Info.plist` contains `CFBundleURLTypes` entry:
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
      <dict>
          <key>CFBundleTypeRole</key>
          <string>Editor</string>
          <key>CFBundleURLSchemes</key>
          <array>
              <string>melsava</string>
          </array>
      </dict>
  </array>
  ```
- [ ] App Store distribution certificate and provisioning profile installed.
- [ ] Build release IPA:
  ```bash
  flutter build ipa --release
  ```

---

## 8. Quality Assurance & Static Analysis Verification

Run the following checks on the clean build directory before publishing:

- [ ] Code formatting check:
  ```bash
  dart format --output=none --set-exit-if-changed .
  ```
- [ ] Static analyzer check (0 warnings, 0 errors):
  ```bash
  flutter analyze
  ```
- [ ] Full test suite execution:
  ```bash
  flutter test
  ```
- [ ] Verify test results: 88 passing tests, 0 failures.
