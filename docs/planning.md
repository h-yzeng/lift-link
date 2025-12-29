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

## Future Considerations

### Phase 1 (Foundation) - COMPLETED ✓
- Project scaffolding
- Database schema with RLS
- Offline-first architecture
- Core domain entities

### Phase 2 (Core Features) - NEXT
- Authentication
- Exercise library
- Active workout tracking
- Workout history
- 1RM calculations

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

**Document Version**: 1.0
**Last Updated**: 2025-12-29
