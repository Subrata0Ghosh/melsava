# MELSAVA

**Meet through moments.**

*Less swiping. More living.*

MELSAVA is an experience-first social connection platform for adults. Instead of swiping through endless profiles, users discover shared activities, meet people through real experiences, and choose who they'd like to connect with afterwards — only when the feeling is mutual.

---

## ✨ Features

- **Experience Discovery** — Browse curated activities like coffee meetups, photography walks, board game evenings, and more
- **Small Group Experiences** — Join intimate groups of 3–5 people for genuine interaction
- **Post-Experience Mutual Connection** — Privately choose who you'd like to meet again; connections form only when both people agree
- **Multiple Connection Types** — Friendship, activity partner, casual dating, meaningful dating, serious relationship, marriage-minded, or open to discovery
- **Privacy-First Design** — Selections are always private; rejections are never revealed
- **Real-Time Messaging** — Chat with mutual connections in secure one-to-one conversations
- **Safety Built In** — Reporting, blocking, moderation, and community guidelines from day one

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend | Supabase (PostgreSQL) |
| Authentication | Supabase Auth |
| File Storage | Supabase Storage |
| Real-Time | Supabase Realtime |
| Server Logic | Supabase Edge Functions (TypeScript) |

## 📋 Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- [Dart SDK](https://dart.dev/get-dart) (bundled with Flutter)
- A [Supabase](https://supabase.com/) account (free tier works for development)
- Android Studio or VS Code with Flutter extensions
- An Android device or emulator for testing

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/melsava.git
cd melsava
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment

Copy the example environment file and fill in your Supabase credentials:

```bash
cp .env.example .env
```

Edit `.env` with your values:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

> [!CAUTION]
> Never commit `.env` to version control. The `.gitignore` is already configured to exclude it.

### 4. Set Up the Database

Run the SQL migration files in order against your Supabase project:

```
supabase/migrations/001_initial_schema.sql
supabase/migrations/002_rls_policies.sql
supabase/migrations/003_functions.sql
supabase/migrations/004_seed_data.sql
```

### 5. Run the App

```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── app/
│   ├── melsava_app.dart         # Root MaterialApp.router
│   ├── app_router.dart          # GoRouter configuration
│   └── app_theme.dart           # ThemeData & design tokens
├── core/
│   ├── constants/
│   │   ├── app_constants.dart   # Brand name, taglines
│   │   ├── app_colors.dart      # Color palette
│   │   └── app_typography.dart  # Font styles
│   ├── services/                # Shared services
│   ├── utils/                   # Utility functions
│   └── widgets/                 # Core reusable widgets
├── features/
│   ├── auth/                    # Authentication screens & logic
│   ├── onboarding/              # Profile setup flow
│   ├── profile/                 # Profile management
│   ├── discovery/               # Discover screen
│   ├── experiences/             # Experience browsing & details
│   ├── connections/             # Mutual connections
│   ├── chat/                    # Messaging
│   └── safety/                  # Reporting & moderation
└── shared/
    ├── models/                  # Data models
    └── widgets/                 # Shared UI components

supabase/
└── migrations/                  # Versioned SQL migrations
```

## 🗺 Development Phases

| Phase | Focus | Status |
|---|---|---|
| 1 | Foundation — Project setup, theme, navigation, auth UI | 🔄 In Progress |
| 2 | Onboarding — Adult eligibility, profile creation, interests | ⬜ Planned |
| 3 | Experience Discovery — Browse, detail, RSVP, capacity | ⬜ Planned |
| 4 | Post-Experience Connection — Mutual selection, connection creation | ⬜ Planned |
| 5 | Messaging — Conversations, real-time chat, blocking | ⬜ Planned |
| 6 | Safety — Reporting, moderation, account deletion, privacy | ⬜ Planned |
| 7 | Testing — Security, RLS, navigation, multi-account, performance | ⬜ Planned |
| 8 | Closed Beta — One-city launch, seed content, feedback | ⬜ Planned |

See [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md) for detailed checklists.

## 🤝 Contributing

Contributions are welcome! Before contributing, please:

1. Read the [PRODUCT_OVERVIEW.md](PRODUCT_OVERVIEW.md) to understand the product vision
2. Review the [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) for UI/UX guidelines
3. Follow the existing code style and architecture patterns
4. Write tests for new features
5. Keep pull requests focused on a single change

### Development Workflow

```bash
# Format code
dart format .

# Analyze for issues
flutter analyze

# Run tests
flutter test

# Apply fixes
dart fix --apply
```

## 📚 Documentation

| Document | Description |
|---|---|
| [PRODUCT_OVERVIEW.md](PRODUCT_OVERVIEW.md) | Vision, mission, and product strategy |
| [APP_WORKFLOW.md](APP_WORKFLOW.md) | Complete user journey documentation |
| [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) | Colors, typography, components, and design principles |
| [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md) | Phase-by-phase implementation plan |
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | Database tables and relationships |
| [SECURITY_AND_RLS.md](SECURITY_AND_RLS.md) | Row Level Security policies |
| [assets/ASSET_LICENSES.md](assets/ASSET_LICENSES.md) | Third-party asset attributions |

## 📄 License

*License to be determined.*

This project is currently in private development. All rights reserved until a license is chosen.

---

<p align="center">
  <strong>MELSAVA</strong> — Meet through moments.<br>
  <em>People don't always connect by looking at profiles. Sometimes they connect by doing something together.</em>
</p>
