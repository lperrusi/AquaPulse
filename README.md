# Hydration Tracker

A cross-platform Flutter app for tracking daily water intake with personalized goals, smart reminders, and gamified streaks.

---

## Table of Contents
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Testing](#testing)
- [Contributing](#contributing)
- [File/Folder Overview](#filefolder-overview)

---

## Features

### ✅ MVP Features Implemented

1. **User Registration/Profile Setup**
   - Email-based user registration
   - Weight and activity level input
   - Location data collection (ready for weather integration)

2. **Personalized Hydration Goal**
   - Calculates daily water goal based on weight and activity level
   - Weather-based adjustments (placeholder for future API integration)
   - Extensible architecture for AI/ML adaptation

3. **Water Intake Logging**
   - Quick-add buttons with customizable cup sizes (250ml, 350ml, 500ml, 750ml)
   - Custom amount input
   - Daily progress tracking with visual indicators

4. **Smart Reminders**
   - Local notification system
   - Customizable reminder times and days
   - Toggle reminders on/off

5. **Visual Dashboard**
   - Circular progress indicator
   - Daily intake history
   - Real-time progress updates

6. **Offline Mode**
   - SQLite database for local data persistence
   - Works without internet connection

7. **Gamified Streaks**
   - Daily streak tracking
   - Achievement levels (Newcomer → Hydration Master)
   - Progress to next milestones

8. **Dark Mode Support**
   - Material 3 design system
   - Automatic theme switching based on system preference

### 🚀 Future Enhancements

- **Google Fit / Apple Health Integration** (placeholder ready)
- **Weather API Integration** (architecture prepared)
- **AI/ML-based Goal Adaptation** (extensible service layer)
- **Advanced Analytics** (charts and insights)
- **Social Features** (sharing achievements)

---

## Architecture

### Clean Architecture Principles
- **Separation of Concerns:** Models, business logic, state, and UI are separated.
- **Riverpod:** Used for state management and dependency injection.
- **Service Layer:** All business logic and external integrations are in `lib/services/`.
- **Persistence:** Local SQLite database via `sqflite`.
- **Extensibility:** Easy to add new features (e.g., health APIs, weather, analytics).

---

## Project Structure

```
lib/
├── main.dart            # App entry point, theme, and routing
├── models/              # Data models (User, WaterIntake, Reminder, etc.)
├── services/            # Business logic, database, notifications, hydration logic
├── providers/           # Riverpod providers for state management
├── screens/             # UI screens (dashboard, onboarding, profile, etc.)
├── widgets/             # Reusable UI components (progress card, buttons, etc.)
├── utils/               # Utility functions (date, formatting, etc.)
```

---

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd hydration_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Dependencies

See `pubspec.yaml` for all dependencies. Key packages:
- `flutter_riverpod` (state management)
- `sqflite`, `path` (local database)
- `flutter_local_notifications`, `timezone` (reminders)
- `fl_chart`, `google_fonts`, `flutter_svg` (UI)
- `intl`, `shared_preferences`, `uuid` (utilities)
- `geolocator`, `geocoding` (location, future weather)

---

## Usage

### First Time Setup
1. Launch the app
2. Complete onboarding (email, name, weight, activity level)
3. Your personalized hydration goal is calculated automatically

### Daily Usage
- **Add Water Intake:** Quick-add or custom amounts
- **Set Reminders:** Custom times/days, toggle on/off
- **Track Progress:** Dashboard, statistics, streaks
- **Edit Profile:** Update personal info and hydration goal

---

## Testing

### Run Unit Tests
```bash
flutter test
```

### Test Coverage
- Hydration goal calculations
- Progress tracking
- Weather adjustments
- Utility functions

---

## Contributing

### How to Contribute
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes (add doc comments, tests, features, etc.)
4. Run tests (`flutter test`)
5. Commit and push (`git commit -m "Describe your change"`)
6. Open a Pull Request

### Adding a New Feature
- Add new models to `lib/models/`
- Add business logic to `lib/services/`
- Add state management to `lib/providers/`
- Add UI to `lib/screens/` and reusable widgets to `lib/widgets/`
- Document your code with Dart doc comments
- Add/expand tests in `test/`

### Code Style
- Use Dart/Flutter best practices
- Use doc comments (`///`) for all public classes and methods
- Keep UI, logic, and state separate

---

## File/Folder Overview

- **lib/main.dart**: App entry, theme, and routing
- **lib/models/**: Data models (User, WaterIntake, Reminder, Streak, CupSize)
- **lib/services/**: Business logic (database, hydration, notifications)
- **lib/providers/**: Riverpod providers for state/state management
- **lib/screens/**: UI screens (dashboard, onboarding, profile, reminders, stats)
- **lib/widgets/**: Reusable UI components (progress card, buttons, streak card, etc.)
- **lib/utils/**: Utility functions (date, formatting, etc.)

---

## Contact
For questions or suggestions, open an issue or contact the maintainer.
