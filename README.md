# Quran AI 📖

A premium Islamic mobile app UI built with **Flutter + Material 3** — read, learn, and (soon) perfect your Quran recitation with AI feedback.

> **Status:** Full UI + a working **Node.js/Express + MongoDB backend** with JWT auth. Login/Register hit the real API; everything else stays browsable in guest mode with mock data. The AI Tajweed engine is still UI-only.

## Getting started

**1. Backend** (needs Node 18+ and MongoDB — local `mongod` or a free Atlas cluster):

```bash
cd quran_ai/backend
npm install
cp .env.example .env      # set MONGODB_URI and JWT_SECRET
npm run dev               # API on http://localhost:5000
```

**2. Flutter app:**

```bash
cd quran_ai
flutter create .          # generates android/ ios/ etc. (won't touch lib/)
flutter pub get
flutter run
```

Requires Flutter 3.27+ (uses `CardThemeData`, `surfaceContainerHighest`, `SliverList.separated`).

The app points at `http://10.0.2.2:5000/api` (Android emulator) by default — see [`lib/core/network/api_config.dart`](lib/core/network/api_config.dart), or override at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:5000/api
```

## Backend & data layer

- **API:** Express + Mongoose in [`backend/`](backend/) — auth (JWT + bcrypt), reading progress with streak logic, bookmarks, tasbeeh/quiz/recitation stats. Full endpoint table in [`backend/README.md`](backend/README.md).
- **Flutter network layer:** `dio` client with an auth interceptor ([`core/network/`](lib/core/network/)), JWT persisted via `shared_preferences`.
- **Repositories:** `AuthRepository` (wired into Login/Register/Splash/Profile), `QuranRepository` (progress + bookmarks), `StatsRepository` (activity uploads) — ready to wire into the remaining screens.
- **Guest mode:** without a session the whole app runs on mock data; a stored token is restored silently on splash and returning users skip straight to the app.

## What's inside

**20 screens:** Splash · Onboarding (3 pages) · Welcome · Login · Register · Home Dashboard · Quran (list, search, Juz filter, bookmarks) · Surah Details (reading view + audio player) · AI Tajweed Checker (record → analyze → score/mistakes/chart) · Hadith · Daily Duas · Prayer Times · Qibla compass · Tasbeeh counter · Learning Center · Quiz · Profile · Settings · Notifications · Global Search

**Navigation:** 5-tab floating bottom bar — Home / Quran / Learn / AI / Profile — plus route-based detail screens with custom fade/slide transitions.

## Architecture

Feature-first, presentation layer only for now:

```
lib/
├── main.dart / app.dart      # Entry, MaterialApp, ThemeController
├── core/
│   ├── constants/            # AppSpacing, AppRadius, AppDurations, AppCurves
│   ├── router/               # Route names + page transitions
│   └── utils/                # BuildContext extensions
├── theme/                    # AppColors, AppTypography, AppTheme (M3, light+dark)
├── shared/
│   ├── data/mock_data.dart   # Realistic content (replaced by repositories later)
│   └── widgets/              # AppButton, AppCard, GlassCard, AppChip, SearchBar,
│                             # ProgressRing, Skeleton, StatCard, AudioPlayerBar, Dialogs
└── features/<feature>/       # One folder per feature, screen + local widgets/
```

When the backend arrives, each feature gains `data/` and `domain/` layers beside its existing presentation code — no restructuring needed.

## Localization 🌍

Full English + **Uzbek (Oʻzbekcha)** support, no codegen required:

- All UI strings live in [`lib/core/localization/app_localizations.dart`](lib/core/localization/app_localizations.dart) as typed getters — `_t('English', 'Oʻzbekcha')` pairs, side by side.
- Wired through Flutter's `Localizations` system (`AppLocalizations.delegate` + `flutter_localizations` global delegates), so locale changes rebuild every screen correctly.
- Follows the **system locale** by default; users can override in **Settings → Til / Language** (System / English / Oʻzbekcha) — switches live, like the theme toggle.
- Access anywhere via `context.l10n.<key>`; parameterized strings are methods (`l10n.verseOfTotal(120, 286)`).
- Prayer names localize to the Uzbek tradition (Fajr→Bomdod, Dhuhr→Peshin, Maghrib→Shom, Isha→Xufton).
- *Content* strings (hadith translations, dua bodies, quiz questions, surah meanings) intentionally stay in the mock-data layer — they'll come localized from the backend/data layer later.

To add a language: add its `Locale` to `supportedLocales` and extend the `_t` helper.

## Design system

| Token | Light | Dark |
|---|---|---|
| Primary | `#0E9D7B` emerald | `#3DBD9C` |
| Secondary | `#1E3A5F` deep navy | `#3E5F8A` |
| Accent | `#E3B23C` gold | same |
| Background | `#F7F8FA` | `#0B1220` |
| Surface | `#FFFFFF` | `#131C2E` |

- **Typography:** Plus Jakarta Sans (UI) + Amiri (Quranic Arabic), full display→caption scale
- **Shape:** 10–32 px radii tokens, hairline borders + soft shadows
- **Motion:** 150/250/400 ms tokens, easeOutCubic entrances, pulse rings on the mic, animated progress rings and bar charts, shimmer skeletons
- **Dark mode:** first-class — every color has a dark variant, toggle in Settings

## Deferred (by design)

Backend APIs · authentication · real audio recording/playback · the AI Tajweed engine · prayer-time calculation · compass sensors · persistence.
