# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                      # Install dependencies
flutter run                          # Run the app (debug mode)
flutter test                         # Run all tests
flutter test test/<file>.dart        # Run a single test file
flutter analyze                      # Static analysis / linting
flutter build apk                    # Build Android release
flutter build ios                    # Build iOS release
```

Code generation (after modifying annotated files):
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

Flutter app using **Riverpod** for state management, **SQLite** (sqflite) for local persistence, and **Firebase** (Firestore, Auth, Storage, Analytics) as the cloud backend. Offline-first: all data writes go to SQLite first; Firestore syncs when connected.

### Layer Overview

**`lib/providers/app_providers.dart`** — All Riverpod providers and StateNotifiers in one file (~1400 lines). Mutable state uses `StateNotifierProvider`; derived/computed state uses `Provider`. UI widgets extend `ConsumerWidget` or `ConsumerStatefulWidget`.

**`lib/services/`** — Singleton services, each injected via a Riverpod `Provider`. Key services:
- `DatabaseService` — SQLite via sqflite (schema v3); CRUD for all domain models
- `FirebaseService` — Firestore, Firebase Auth, Firebase Storage, Cloud Functions
- `AuthService` — Login/register with fallback chain: Firebase → Firestore → SQLite → SharedPreferences
- `HydrationService` — Goal calculation: `base = weight × 32.5ml × activityMultiplier`, then weather-adjusted (+10–20% above 25 °C)
- `NotificationService` — Local notifications via `flutter_local_notifications`; schedules 4 weeks ahead; supports fixed-time and interval modes
- `WeatherService` — OpenWeatherMap via Firestore proxy or direct API; 30-min cache
- `AdService` — Google Mobile Ads; interstitial shown after every 3rd water log

**`lib/models/`** — `User`, `WaterIntake`, `DailyWaterGoal`, `Reminder`, `Streak`, `Achievement`, `CupSize`, `Friend`, `Leaderboard`

**`lib/screens/`** — 18 screens. Navigation logic lives in `AppRouter` (`lib/main.dart`):
- No intro seen → `IntroductionScreen`
- Not authenticated → `OnboardingScreen`
- Authenticated → `DashboardScreen`

### Key Patterns

- **Feature toggles**: `lib/config/app_capabilities.dart` (`authEnabled`, `cloudSocialEnabled`) gates online features
- **UI styling**: neumorphic design system in `lib/utils/neumorphic_style.dart` (primary blue `#2196F3`, soft dual shadows)
- **Social features** (friends, challenges, leaderboard): driven by real-time Firestore streams in `FriendService`, `ChallengeService`, `LeaderboardService`
- **Smart notifications**: `NotificationAnalyticsService` analyzes 30-day intake patterns to suggest optimal reminder hours

### Testing

Tests live in `test/`. Uses `mockito` for mocks and `sqflite_common_ffi` to run SQLite in tests. There are 18 test files covering services, providers, models, and UI widgets.
