# LiftLink - Project Planning Document

## Project Overview

LiftLink is a cross-platform fitness tracking application that allows users to log workouts, track progress, and connect with friends for motivation. The app emphasizes offline-first functionality with cloud synchronization, allowing users to track their fitness journey regardless of connectivity.

**Core Features:**

- Workout tracking with exercise library (system + custom exercises)
- Automatic 1RM calculations using the Epley Formula
- Friend connections with shared progress visibility
- Offline-first architecture with cloud sync
- Cross-platform support (Windows Desktop, iOS, Android)

## Architecture

LiftLink follows **Clean Architecture** principles with strict separation of concerns across three layers.

### Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│    (Flutter Widgets, Riverpod Providers, State Management)   │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                            │
│         (Entities, Use Cases, Repository Interfaces)         │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                             │
│    (Repository Implementations, Data Sources, Models)        │
│              ┌─────────────┬─────────────┐                  │
│              │    Local    │   Remote    │                  │
│              │   (Drift)   │ (Supabase)  │                  │
│              └─────────────┴─────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

#### 1. Presentation Layer (`lib/features/*/presentation/`)

- **Responsibility**: UI components, state management, user interactions
- **Technology**: Flutter widgets, Riverpod providers with code generation
- **Rules**: Can depend on Domain layer only, never directly on Data layer
- **Components**: Pages, widgets, Riverpod providers

#### 2. Domain Layer (`lib/features/*/domain/`)

- **Responsibility**: Business logic, entities, use cases
- **Technology**: Pure Dart (no Flutter dependencies)
- **Rules**: Zero dependencies on other layers - completely independent
- **Components**: Entities (with freezed), repository interfaces, use cases

#### 3. Data Layer (`lib/features/*/data/`)

- **Responsibility**: Data fetching, persistence, external APIs
- **Technology**: Drift (local SQLite), Supabase (remote PostgreSQL)
- **Rules**: Implements interfaces defined in Domain layer
- **Components**: Models, data sources (local/remote), repository implementations

### Offline-First Data Flow

LiftLink uses an **offline-first** approach where local data (Drift/SQLite) is the source of truth for the UI.

**Read Operations:**

- Always read from Drift (local SQLite)
- Background sync pulls from Supabase when online

**Write Operations:**

1. Write to Drift immediately (instant UI update)
2. Mark as `isPendingSync: true`
3. Sync to Supabase when online
4. Update `syncedAt` and clear `isPendingSync` flag

**Conflict Resolution:**

- Last-write-wins based on `updated_at` timestamp

## Data Model

### Database Schema (PostgreSQL via Supabase)

**Core Tables:**

- `profiles` - User profiles (1:1 with auth.users)
- `exercises` - Exercise library (system + custom)
- `workout_sessions` - Individual workouts
- `exercise_performances` - Junction: workouts ↔ exercises
- `sets` - Individual sets with weight/reps/RPE
- `friendships` - Friend relationships (self-referencing)

**Important Notes:**

- **1RM is NEVER stored** - always calculated client-side using Epley Formula: `weight × (1 + reps/30)`
- All tables use UUID primary keys
- Row Level Security (RLS) is enabled on all tables
- `updated_at` triggers auto-update on all tables

### Row Level Security (RLS)

All data access is secured at the Supabase database level:

**Profiles**: Users can view/edit their own + view accepted friends' profiles
**Exercises**: All see system, users see own custom
**Workouts/Sets**: Users can view/edit own + view accepted friends' data
**Friendships**: Users see where they're involved

## Technology Stack

### Frontend

- **Framework**: Flutter 3.38.5+
- **State Management**: Riverpod with code generation
- **Local Database**: Drift (SQLite)
- **Data Classes**: Freezed for immutability
- **JSON**: json_serializable
- **Error Handling**: Dartz for `Either<Failure, Result>`
- **Network**: connectivity_plus

### Backend

- **BaaS**: Supabase (PostgreSQL + Auth + Realtime)
- **Authentication**: Supabase Auth
- **Database**: PostgreSQL 15+

### Development Tools

- **Code Generation**: build_runner
- **Linting**: flutter_lints
- **Platforms**: Windows, iOS, Android

## Project Structure

```
LiftLink/
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/              # Shared infrastructure
│   │   ├── features/          # Feature modules
│   │   │   ├── auth/
│   │   │   ├── workout/
│   │   │   ├── social/
│   │   │   └── profile/
│   │   └── shared/            # Shared components
│   ├── test/
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── backend/
│   └── supabase/
│       └── migrations/        # SQL migrations
└── docs/                      # Documentation
```

## Testing Strategy

**Unit Tests**: Domain entities, use cases
**Widget Tests**: UI components
**Integration Tests**: End-to-end feature flows

**Coverage Goals:**

- Domain layer: 100%
- Data layer: 80%+
- Presentation layer: 60%+

## Development Commands

### Initial Setup

```bash
cd frontend
flutter create . --platforms=windows,android,ios
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

cd ../backend/supabase
supabase start
supabase db reset
```

### Running

```bash
cd frontend
flutter run -d windows
```

### Testing

```bash
flutter test
flutter test --coverage
```

### Database

```bash
cd backend/supabase
supabase migration new description
supabase db reset
supabase status
```

## Development Guidelines

### Code Style

- Single quotes for strings
- Trailing commas required
- Package imports (not relative)
- Const constructors where possible
- Prefer `final` over `var`
- Always declare return types

### Adding Features

1. Create Domain Entity (`domain/entities/`)
2. Define Repository Interface (`domain/repositories/`)
3. Create Data Model (`data/models/`)
4. Implement Data Sources (`data/datasources/`)
5. Implement Repository (`data/repositories/`)
6. Create Providers (`presentation/providers/`)
7. Build UI (`presentation/pages/` and `widgets/`)

## Security Considerations

- RLS enabled on all tables (enforced at database level)
- Never commit `.env` files
- Supabase anon key is safe for client-side (respects RLS)
- Never use service_role key in client code
- JWT tokens managed automatically by Supabase SDK

## Development Phases

### Phase 1 (Foundation) - ✅ COMPLETED (2025-12-29)

- ✅ Project scaffolding
- ✅ Database schema with RLS
- ✅ Offline-first architecture
- ✅ Core domain entities
- ✅ Documentation

### Phase 2 (Core Features) - 🔄 IN PROGRESS (100% Complete)

- ✅ Authentication (COMPLETED 2025-12-29)
  - User entity with email/password support
  - Login and registration flows
  - Auth state management with Riverpod
  - Route protection based on auth state
- ✅ Exercise Library Browser (COMPLETED 2025-12-29)
  - Search and filter functionality
  - Offline-first with background sync
  - 20 seeded system exercises
  - Custom exercise support
  - Color-coded muscle group display
- ✅ Active workout tracking (COMPLETED 2025-12-29)
  - Start/complete workout functionality
  - Add exercises to workouts
  - Add sets with weight, reps, RPE tracking
  - Real-time 1RM calculation using Epley formula
  - Live workout stats (duration, volume, sets)
  - Offline-first with background sync
  - Complete domain/data/presentation layers
- ⏳ Workout history (NEXT)

### Phase 3 (Social)

- Friend requests
- Activity feed
- Shared workouts

### Phase 4 (Analytics)

- Progress charts
- Personal records
- Muscle frequency analysis

### Phase 5 (Advanced)

- Workout templates
- Rest timer
- Exercise videos
- Data export

---

## Recent Updates

### 2025-12-29 - Active Workout Tracking Complete

**Completed Work:**

- Full active workout tracking system following Clean Architecture
- Domain layer: WorkoutRepository interface, 6 use cases (start, add exercise, add set, complete, get history, get active)
- Data layer: 3 models with Drift/Supabase mappers, local/remote data sources with complex queries, offline-first repository
- Presentation layer: Riverpod providers, ActiveWorkoutPage, SetInputRow, OneRMDisplay widgets
- Live workout stats with real-time 1RM calculations using Epley formula
- Hierarchical data management (WorkoutSession → ExercisePerformance → WorkoutSet)
- Offline-first with background sync and pending sync tracking

**Files Added:**

- `features/workout/domain/repositories/workout_repository.dart`
- `features/workout/domain/usecases/*` (6 use cases)
- `features/workout/data/models/*` (workout_session_model, exercise_performance_model, workout_set_model)
- `features/workout/data/datasources/workout_local_datasource.dart` (complex Drift queries)
- `features/workout/data/datasources/workout_remote_datasource.dart` (nested Supabase queries)
- `features/workout/data/repositories/workout_repository_impl.dart` (offline-first implementation)
- `features/workout/presentation/providers/workout_providers.dart`
- `features/workout/presentation/widgets/one_rm_display.dart`
- `features/workout/presentation/widgets/set_input_row.dart`
- `features/workout/presentation/pages/active_workout_page.dart`

**Files Modified:**

- `shared/database/tables/workout_sessions_table.dart` - Added exerciseName to ExercisePerformances
- `features/workout/presentation/pages/exercise_list_page.dart` - Added selection mode for adding exercises to workouts
- `features/auth/presentation/pages/home_page.dart` - Added start workout and active workout display

**Bug Fixes:**

- Fixed ambiguous import for networkInfoProvider
- Fixed Supabase query syntax (filter vs gte/lte)
- Fixed missing userMessage imports

**Next Steps:**

1. Implement workout history view to see past workouts
2. Add workout summary statistics
3. Implement personal records tracking

---

### 2025-12-29 - Exercise Library Browser Complete

**Completed Work:**

- Full exercise library browser with search and filtering
- Domain layer: Repository interface, 3 use cases
- Data layer: Local/remote data sources, offline-first repository
- Presentation layer: Riverpod providers, exercise card widget, list page with filters
- Initial sync logic: Automatically syncs on first launch when local DB is empty
- Search functionality: Real-time search by exercise name or description
- Filtering: By muscle group, equipment type, custom-only toggle
- 20 system exercises seeded in database

**Files Added:**

- `features/workout/domain/repositories/exercise_repository.dart`
- `features/workout/domain/usecases/*` (3 use cases)
- `features/workout/data/models/exercise_model.dart`
- `features/workout/data/datasources/*` (local + remote)
- `features/workout/data/repositories/exercise_repository_impl.dart`
- `features/workout/presentation/providers/exercise_providers.dart`
- `features/workout/presentation/widgets/exercise_card.dart`
- `features/workout/presentation/pages/exercise_list_page.dart`

**Files Modified:**

- `features/auth/presentation/pages/home_page.dart` - Added exercise library navigation

**Bug Fixes:**

- Fixed missing networkInfo provider
- Added synchronous initial sync for empty local database
- Fixed import issues for userMessage extension

**Next Steps:**

1. Implement active workout tracking to log exercises and sets
2. Add workout history view
3. Display 1RM calculations in workout tracking

---

### 2025-12-29 - Authentication System Complete

**Completed Work:**

- Full authentication system implementation following Clean Architecture
- Domain layer: User entity, auth repository interface, 4 use cases
- Data layer: Supabase integration, local caching, repository implementation
- Presentation layer: Riverpod providers, login/register/home pages
- Infrastructure: Added shared_preferences, configured local Supabase
- Code quality: Zero compilation errors, all code generation complete

**Files Added:**

- `features/auth/domain/entities/user.dart`
- `features/auth/domain/repositories/auth_repository.dart`
- `features/auth/domain/usecases/*` (4 use cases)
- `features/auth/data/models/user_model.dart`
- `features/auth/data/datasources/*` (remote + local)
- `features/auth/data/repositories/auth_repository_impl.dart`
- `features/auth/presentation/providers/auth_providers.dart`
- `features/auth/presentation/pages/*` (login, register, home)

**Files Modified:**

- `pubspec.yaml` - Added shared_preferences dependency
- `app.dart` - Auth state routing
- `supabase_config.dart` - Local development defaults

**Next Steps:**

1. Build exercise library browser to view system and custom exercises
2. Implement active workout tracking for logging sets and exercises
3. Add workout history view to see past performance

---

**Document Version**: 1.3
**Last Updated**: 2025-12-29 (Active Workout Tracking completed)
