<div align="center">

# LiftLink

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Web](https://img.shields.io/badge/Web-4285F4?style=for-the-badge&logo=google-chrome&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**A cross-platform fitness tracking app with offline-first architecture**

_Version 2.5.0 • Production Ready • 283 Tests Passing • 0 Errors_

[Features](#features) • [Screenshots](#screenshots) • [Tech Stack](#tech-stack) • [Getting Started](#getting-started) • [Architecture](#architecture)

</div>

---

## About

LiftLink is a modern fitness tracking application that helps you log workouts, track progress, and connect with friends for motivation. Built with **Flutter** and **Supabase**, it features a robust offline-first architecture that ensures your workout data is always available, even without internet connectivity.

### Features

#### Core Tracking

- **Workout Tracking** - Log exercises, sets, reps, weight, RPE, and RIR
- **Automatic 1RM Calculation** - Real-time estimated one-rep max using Epley Formula
- **Exercise Library** - 20+ pre-loaded exercises with smart sorting by recent usage
- **Workout History** - View all past workout sessions with filtering
- **Workout Templates** - Create and reuse workout routines
- **Rest Timer** - Auto-start countdown timer with customizable intervals
- **Plate Calculator** - Visual barbell loading calculator with color-coded plates
- **Progressive Overload** - Smart weight increase suggestions (2.5% increments)
- **Exercise Notes** - Quick notes per exercise during workouts
- **Warmup Generator** - Automatic warmup set recommendations

#### Analytics & Progress

- **Personal Records** - Track PRs with automatic rank indicators (Bronze, Silver, Gold, Diamond)
- **Progress Charts** - Visualize volume, 1RM, and muscle frequency over time
- **Advanced Analytics Dashboard** - Comprehensive workout insights with heatmaps and trends
- **Muscle Frequency Analysis** - Pie chart breakdown of muscle group training
- **Volume Tracking** - Track total volume per muscle group over time
- **PDF Export** - Export workouts as professional PDF documents with charts
- **Data Export** - Export workout data in JSON or CSV format

#### Social Features

- **Friend System** - Send and accept friend requests
- **Activity Feed** - See friends' recent workout activity
- **User Search** - Find and connect with other users
- **Profile Management** - Customizable username, display name, and bio
- **Workout Sharing** - Generate and share workout summary cards
- **Social Posts** - Share achievements on external platforms (4 formats)
- **Smart Recommendations** - AI-like workout pattern analysis and suggestions
- **Rest Day Suggestions** - Intelligent rest recommendations based on training patterns

#### Technical Features

- **Offline-First** - Full functionality without internet connection
- **Cloud Sync** - Automatic synchronization when online
- **Query Caching** - In-memory cache with TTL for improved performance
- **Lazy Loading** - Efficient pagination for exercise history
- **Secure** - Row-level security with Supabase
- **Cross-Platform** - Windows Desktop ✅, Web ✅, Android ✅, iOS ✅
- **Progressive Web App** - Installable web app with IndexedDB offline support
- **API Documentation** - Comprehensive dartdoc for 204 libraries

### Screenshots

> Coming soon - App is currently in development

---

## Tech Stack

### Frontend

- **Framework**: Flutter 3.38+
- **Language**: Dart 3.2+
- **State Management**: Riverpod with code generation
- **Local Database**: Drift (SQLite wrapper)
- **Data Classes**: Freezed for immutability
- **JSON**: json_serializable
- **PDF Generation**: pdf package
- **Sharing**: share_plus package

### Backend

- **BaaS**: Supabase (PostgreSQL + Auth + Realtime)
- **Database**: PostgreSQL 15+
- **Authentication**: Supabase Auth
- **Row-Level Security**: Enabled on all tables

### Architecture

- **Pattern**: Clean Architecture (3-layer)
- **Offline Strategy**: Local-first with background sync
- **Error Handling**: Functional programming with Dartz (`Either<Failure, Result>`)

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.2.0+
- [Dart SDK](https://dart.dev/get-dart) 3.2.0+
- [Supabase CLI](https://supabase.com/docs/guides/cli) (via Scoop or npm)
- [Docker Desktop](https://www.docker.com/products/docker-desktop) (for local Supabase)
- Git

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/LiftLink.git
   cd LiftLink
   ```

2. **Set up Flutter project**

   ```bash
   cd frontend
   flutter create . --platforms=windows,android,ios
   flutter pub get
   ```

3. **Start local Supabase**

   ```bash
   cd ../backend/supabase
   supabase start
   supabase db reset
   ```

4. **Generate code**

   ```bash
   cd ../../frontend
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**

   **For Windows Desktop:**

   ```bash
   flutter run -d windows
   ```

   **For Web Browser:**

   ```bash
   flutter run -d chrome  # or 'edge' for Microsoft Edge
   ```

   **For Mobile:**

   ```bash
   flutter run -d <device>  # iOS/Android device or emulator
   ```

### Building for Production

**Windows Desktop (.exe):**

```bash
cd frontend
flutter build windows --release
# Output: build/windows/x64/runner/Release/liftlink.exe
```

**Web (PWA):**

```bash
cd frontend
flutter build web --release
# Output: build/web/ (deploy to static hosting)
# Features: PWA manifest, service worker, installable
```

**Note**: Web deployment requires database adapter changes (SQLite uses FFI which isn't supported on web). The app can run on web using Supabase-only mode or IndexedDB. See [docs/setup-guide.md](docs/setup-guide.md) for web configuration.

**Android (.apk / .aab):**

```bash
flutter build apk --release  # APK for direct installation
flutter build appbundle      # AAB for Google Play Store
```

**iOS (.ipa):**

```bash
flutter build ios --release  # Requires Apple Developer account
```

### Configuration

Set your Supabase credentials via environment variables:

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

For production, replace with your Supabase Cloud URL and key.

---

### Key Design Decisions

**Offline-First Architecture**

- Drift (SQLite) serves as the source of truth for the UI
- All writes go to local database first for instant feedback
- Background sync to Supabase when connectivity is available
- Last-write-wins conflict resolution

**1RM Calculation**

- Calculated client-side using Epley Formula: `weight × (1 + reps/30)`
- Never stored in database to allow formula updates without migration
- Computed property on `WorkoutSet` entity

**Security**

- Row-Level Security (RLS) enforced at database level
- Users can only access their own data
- Accepted friends can view (but not modify) each other's workouts

For detailed architecture documentation, see [docs/architecture.md](docs/architecture.md).

---

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/workout_set_test.dart
```

**Test Coverage Goals:**

- Domain layer: 100% (pure business logic)
- Data layer: 80%+
- Presentation layer: 60%+

---

## Contributing

Contributions are welcome! This project follows Clean Architecture principles and uses Flutter best practices.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Development Guidelines:**

- Follow Clean Architecture layers
- Use Freezed for data classes
- Write tests for new features
- Run code generation after model changes
- Ensure RLS policies for new database tables

See [docs/planning.md](docs/planning.md) for detailed development guidelines.

---

## Author

**Henry Zeng**

- GitHub: [@h-yzeng](https://github.com/h-yzeng)
- Email: thyzeng@gmail.com

</div>
