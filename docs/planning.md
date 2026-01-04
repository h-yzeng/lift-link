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

| Table                   | Description                          |
| ----------------------- | ------------------------------------ |
| `profiles`              | User profiles (1:1 with auth.users)  |
| `exercises`             | Exercise library (system + custom)   |
| `workout_sessions`      | Individual workouts                  |
| `exercise_performances` | Junction: workouts ↔ exercises       |
| `sets`                  | Individual sets with weight/reps/RPE |
| `friendships`           | Friend relationships                 |

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

## Current Development Focus

All core features and 16 development phases completed. Focus is on optimization and future enhancements.

### Active Tasks

- [ ] Manual accessibility testing with screen readers

### Backlog Optimizations

**Database Optimization:**

- Implement query result caching
- Use database views for complex queries
- Optimize JOIN operations

**State Management:**

- Implement selective provider rebuilds
- Add provider caching with TTL
- Reduce unnecessary rebuilds

**UI Performance:**

- Lazy load images and heavy content

**Memory Management:**

- Limit cached data size
- Profile memory usage

---

## Development Commands

```bash
# Setup
cd frontend && flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Run
flutter run -d windows

# Test
flutter test

# Analyze
flutter analyze

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

## Application Evaluation

| Category         | Score | Notes                                    |
| ---------------- | ----- | ---------------------------------------- |
| Architecture     | 9/10  | Clean Architecture, excellent separation |
| State Management | 9/10  | Riverpod with code generation            |
| Error Handling   | 9/10  | Type-safe Either pattern, undo stack     |
| Data Layer       | 9/10  | Offline-first, sync queue with retry     |
| UI/UX Components | 9/10  | Validated inputs, search, undo           |
| Documentation    | 7/10  | Strong architecture docs                 |
| Dependencies     | 8/10  | Modern, minimal bloat                    |
| Test Coverage    | 9/10  | 250 tests, 100% pass rate                |
| Performance      | 8/10  | Database indexed, fuzzy search optimized |
| Accessibility    | 6/10  | Semantic labels added                    |

**Overall: 8.7/10** (Updated 2026-01-03)

---

**Document Version**: 4.0
**Last Updated**: 2026-01-03
**Status**: Active Development - 99% complete, 250 tests passing
