# LiftLink - Project Planning Document

## Project Overview

LiftLink is a cross-platform fitness tracking application that allows users to log workouts, track progress, and connect with friends for motivation. The app emphasizes offline-first functionality with cloud synchronization.

**Core Features:**

- Workout tracking with exercise library (system + custom exercises)
- Automatic 1RM calculations using the Epley Formula
- Friend connections with shared progress visibility
- Offline-first architecture with cloud sync
- Cross-platform support (Windows Desktop, iOS, Android)

---

## Architecture

LiftLink follows **Clean Architecture** principles with strict separation of concerns.

### Three-Layer Architecture

```text
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

**Layer Rules:**

- **Presentation**: UI components, state management. Depends on Domain only.
- **Domain**: Business logic, entities, use cases. Zero external dependencies.
- **Data**: Data fetching and persistence. Implements Domain interfaces.

### Offline-First Data Flow

**Read Operations:** Always read from Drift (local SQLite), background sync from Supabase.

**Write Operations:**
1. Write to Drift immediately (instant UI update)
2. Mark as `isPendingSync: true`
3. Sync to Supabase when online
4. Clear `isPendingSync` flag on success

**Conflict Resolution:** Last-write-wins based on `updated_at` timestamp.

---

## Data Model

### Database Schema (PostgreSQL via Supabase)

| Table | Description |
|-------|-------------|
| `profiles` | User profiles (1:1 with auth.users) |
| `exercises` | Exercise library (system + custom) |
| `workout_sessions` | Individual workouts |
| `exercise_performances` | Junction: workouts ↔ exercises |
| `sets` | Individual sets with weight/reps/RPE |
| `friendships` | Friend relationships |

**Important:**
- 1RM is NEVER stored - calculated client-side using Epley Formula
- All tables use UUID primary keys
- Row Level Security (RLS) enabled on all tables

---

## Technology Stack

### Frontend
- Flutter 3.38.5+
- Riverpod (state management)
- Drift (local SQLite)
- Freezed (immutable data classes)
- Dartz (Either<Failure, Result>)

### Backend
- Supabase (PostgreSQL + Auth)

---

## Project Structure

```text
LiftLink/
├── frontend/lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/           # Shared infrastructure
│   ├── features/       # Feature modules (auth, workout, social, profile, onboarding)
│   └── shared/         # Shared widgets and utilities
├── backend/supabase/
│   └── migrations/     # SQL migrations
└── docs/               # Documentation
```

---

## Development Phases

### Phase 1: Foundation ✅
- Project scaffolding
- Database schema with RLS
- Offline-first architecture
- Core domain entities
- Documentation

### Phase 2: Core Features ✅
- Authentication (login, register, auth state)
- Exercise Library Browser (search, filter, offline-first)
- Active Workout Tracking (sets, reps, 1RM calculation)
- Workout History (summary cards, detail view)

### Phase 3: Social Features ✅
- User search and friend requests
- Friends list management
- Activity feed with friends' workouts
- Shared workout visibility via RLS

### Phase 4: Analytics ✅
- Personal records tracking
- Progress charts (volume, 1RM, frequency)
- Muscle frequency analysis

### Phase 5: Advanced Features ✅
- Workout templates
- Rest timer
- Data export (JSON/CSV)
- Sync service
- Dark mode and settings

### Phase 6: Code Quality & UX Polish ✅
- Onboarding flow
- Custom exercise creation
- Shared widget library
- Dialog helpers and result extensions
- Barrel exports for modules

---

## Development Commands

```bash
# Setup
cd frontend && flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Run
flutter run -d windows

# Database
cd backend/supabase && supabase start
supabase db reset
```

---

## Security

- RLS enabled on all tables
- Never commit `.env` files
- Supabase anon key respects RLS (safe for client)
- Never use service_role key in client code

---

**Document Version**: 2.0
**Last Updated**: 2025-12-31
**Status**: Phase 6 Complete (~97% overall progress)
