<div align="center">

# LiftLink

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**A cross-platform fitness tracking app with offline-first architecture**

[Features](#features) • [Screenshots](#screenshots) • [Tech Stack](#tech-stack) • [Getting Started](#getting-started) • [Architecture](#architecture)

</div>

---

## About

LiftLink is a modern fitness tracking application that helps you log workouts, track progress, and connect with friends for motivation. Built with **Flutter** and **Supabase**, it features a robust offline-first architecture that ensures your workout data is always available, even without internet connectivity.

### Features

#### Core Tracking

- **Workout Tracking** - Log exercises, sets, reps, and weight
- **Automatic 1RM Calculation** - Real-time estimated one-rep max using Epley Formula
- **Exercise Library** - 20+ pre-loaded exercises with search functionality
- **Workout History** - View all past workout sessions
- **Workout Templates** - Create and reuse workout routines
- **Rest Timer** - Built-in countdown timer with customizable intervals

#### Analytics & Progress

- **Personal Records** - Track PRs with automatic rank indicators (Bronze, Silver, Gold, Diamond)
- **Progress Charts** - Visualize volume, 1RM, and muscle frequency over time
- **Muscle Frequency Analysis** - Pie chart breakdown of muscle group training
- **Data Export** - Export workout data in JSON or CSV format

#### Social Features

- **Friend System** - Send and accept friend requests
- **Activity Feed** - See friends' recent workout activity
- **User Search** - Find and connect with other users
- **Profile Management** - Customizable username, display name, and bio

#### Technical Features

- **Offline-First** - Full functionality without internet connection
- **Cloud Sync** - Automatic synchronization when online
- **Secure** - Row-level security with Supabase
- **Cross-Platform** - Windows, Android, and iOS support

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
   ```bash
   flutter run -d windows  # For Windows
   flutter run -d <device> # For iOS/Android
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

## Architecture

LiftLink follows **Clean Architecture** principles with strict separation of concerns:

```
┌─────────────────────────────────────┐
│      Presentation Layer             │  ← Flutter UI, Riverpod
├─────────────────────────────────────┤
│        Domain Layer                 │  ← Business Logic, Entities
├─────────────────────────────────────┤
│         Data Layer                  │  ← Repositories, Data Sources
│    ┌──────────┬──────────┐          │
│    │  Drift   │ Supabase │          │  ← Local & Remote
│    └──────────┴──────────┘          │
└─────────────────────────────────────┘
```

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

## Project Structure

```
LiftLink/
├── frontend/              # Flutter application
│   ├── lib/
│   │   ├── features/     # Feature modules (auth, workout, social, profile)
│   │   ├── core/         # Shared infrastructure
│   │   └── shared/       # Shared components
│   └── test/             # Unit, widget, and integration tests
├── backend/
│   └── supabase/
│       └── migrations/   # Database migrations with RLS policies
└── docs/                 # Documentation
    ├── planning.md       # Project planning
    ├── task.md          # Task tracking
    ├── architecture.md  # Architecture details
    └── setup-guide.md   # Development setup
```

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

## Roadmap

### Phase 1: Foundation ✅ (Completed)

- [x] Project scaffolding
- [x] Database schema with RLS
- [x] Offline-first architecture
- [x] Core domain entities
- [x] Working Windows desktop app

### Phase 2: Core Features ✅ (Completed)

- [x] Authentication (login, register, password reset)
- [x] Exercise library browser with search
- [x] Active workout tracking
- [x] Workout history viewer
- [x] 1RM calculations and display
- [x] Profile management

### Phase 3: Social ✅ (Completed)

- [x] Friend request system
- [x] Activity feed
- [x] User search and profiles
- [x] Nickname display in friendships

### Phase 4: Analytics ✅ (Completed)

- [x] Progress charts (Volume, 1RM, Frequency)
- [x] Personal records tracking with rank indicators
- [x] Muscle group frequency analysis

### Phase 5: Enhanced Features ✅ (Completed)

- [x] Workout templates
- [x] Rest timer with haptic feedback
- [x] Data export (JSON/CSV)
- [x] Dark mode with system/light/dark options
- [x] Onboarding flow for new users

### Phase 6-13: Completed ✅

- [x] Code quality & UX polish
- [x] Testing & quality assurance
- [x] Static analysis & code cleanup
- [x] Quick wins & core UX improvements
- [x] Quality & reliability improvements
- [x] Advanced improvements (RPE tracking, RIR, weight logging)
- [x] Mobile enhancement features

### Phase 14: Code Quality & Architecture ✅ (Completed)

- [x] Comprehensive accessibility support (WCAG 2.1 AA)
- [x] Field-level sync conflict resolution
- [x] Widget decomposition (active_workout_page: 803→470 lines)
- [x] UI test infrastructure with Riverpod helpers
- [x] Social features pagination foundation

### Phase 15: Advanced Refactoring 🔄 (In Progress)

- [x] setState migration to StateNotifier (2/16 files complete, 9/60 calls)
  - [x] user_search_page.dart migrated to StateNotifier (5 calls)
  - [x] active_workout_page.dart migrated to StateProvider (4 calls)
- [ ] Complete remaining 14 files (51 setState calls)
- [ ] Reduce late initialization pattern usage

### Future Enhancements

- [ ] Exercise videos and form tips
- [ ] Workout notes and photos
- [ ] Nutrition tracking integration
- [ ] iOS & Android releases
- [ ] Web version
- [ ] Workout sharing and challenges

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
