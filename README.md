# LiftLink 💪

<div align="center">

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

## 📖 About

LiftLink is a modern fitness tracking application that helps you log workouts, track progress, and connect with friends for motivation. Built with **Flutter** and **Supabase**, it features a robust offline-first architecture that ensures your workout data is always available, even without internet connectivity.

### ✨ Features

- 🏋️ **Workout Tracking** - Log exercises, sets, reps, and weight
- 📊 **Automatic 1RM Calculation** - Real-time estimated one-rep max using Epley Formula
- 👥 **Social Features** - Connect with friends and share progress
- 📴 **Offline-First** - Full functionality without internet connection
- 🔄 **Cloud Sync** - Automatic synchronization when online
- 🎯 **Exercise Library** - 20+ pre-loaded exercises + custom exercise creation
- 📈 **Progress Tracking** - View workout history and personal records
- 🔒 **Secure** - Row-level security with Supabase

### 🎯 Screenshots

> Coming soon - App is currently in development

---

## 🛠️ Tech Stack

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

## 🚀 Getting Started

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

## 🏗️ Architecture

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

## 📁 Project Structure

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

## 🧪 Testing

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

## 🗺️ Roadmap

### Phase 1: Foundation ✅
- [x] Project scaffolding
- [x] Database schema with RLS
- [x] Offline-first architecture
- [x] Core domain entities
- [x] Working Windows desktop app

### Phase 2: Core Features (In Progress)
- [ ] Authentication (login, register)
- [ ] Exercise library browser
- [ ] Active workout tracking
- [ ] Workout history viewer
- [ ] 1RM calculations and display

### Phase 3: Social
- [ ] Friend request system
- [ ] Activity feed
- [ ] Shared workout viewing

### Phase 4: Analytics
- [ ] Progress charts
- [ ] Personal records tracking
- [ ] Muscle group analysis

### Future
- [ ] Workout templates
- [ ] Rest timer
- [ ] iOS & Android releases
- [ ] Web version

See [docs/task.md](docs/task.md) for detailed task breakdown.

---

## 🤝 Contributing

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

## 👤 Author

**Your Name**
- GitHub: [@h-yzeng](https://github.com/h-yzeng)
- Email: thyzeng@gmail.com
---

<div align="center">

</div>
