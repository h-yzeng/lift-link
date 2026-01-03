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

### Phase 7: Testing & Quality Assurance ✅

- Unit tests for domain entities
- Unit tests for use cases with mocks
- Widget tests for shared components
- 105 total tests passing

### Phase 8: Static Analysis & Code Cleanup ✅

- Fixed flutter analyze issues
- Trailing comma compliance
- Async context handling fixes
- Updated app version to 2.0.0

### Phase 9: Quick Wins - UX Polish ✅

- [x] HapticService utility for consistent feedback
- [x] ShimmerLoading widget with skeleton animations
- [x] Pull-to-refresh on all list pages
- [x] Semantic labels and ExcludeSemantics for accessibility

### Phase 10: Core UX Improvements ✅

- [x] Exercise history per exercise (show previous weights)
- [x] Local notifications for rest timer
- [x] Database performance indexes
- [x] Workout streak tracking

### Phase 11: Quality & Reliability ✅

- [x] Expanded test coverage (229 tests, 100% pass rate)
- [x] Pagination for large datasets
- [x] Fixed all flutter analyze errors (0 issues)
- [x] Fixed all test failures
- [ ] Error monitoring (Sentry/Crashlytics) - SKIPPED per user request

### Phase 12: Advanced Improvements ✅

- [x] Input validation UI widgets (ValidatedTextField)
- [x] Offline queue with exponential backoff and conflict resolution
- [x] Undo functionality with persistent stack
- [x] Search improvements (fuzzy search, history, suggestions)

### Phase 13: Mobile Enhancement Features ✅

- [x] RIR (Reps in Reserve) tracking in workout sets
- [x] Display PR (Personal Record) during workouts
- [x] Bodyweight tracking with WeightLog entity
- [x] Quick weight increment buttons (+/- 2.5, 5, 10)
- [x] Improved empty states across all pages
- [x] Start from previous workout feature

### Phase 14: Code Quality & Architecture Improvements 🔄

- [ ] Comprehensive accessibility support (semantic labels, screen readers)
- [ ] Complete sync merge logic (field-level conflict resolution)
- [ ] Decompose large page widget (active_workout_page.dart - 803 lines)
- [ ] Extend UI test coverage (target 70%+ presentation layer)
- [ ] Implement social features pagination (user search, friends, activity feed)

### Phase 15: Advanced Code Refactoring ⏳

- [ ] Migrate setState to Riverpod StateNotifier (62 occurrences)
- [ ] Reduce late initialization pattern (160+ occurrences)

### Phase 16: Future Features (Backlog)

- Exercise videos/GIFs
- Multi-language support (i18n)
- Apple Watch / Wear OS companion apps

---

## Code Efficiency Plan

### Database Optimization

1. Add indexes on frequently queried columns
2. Implement query result caching
3. Use database views for complex aggregations
4. Optimize N+1 query patterns

### State Management Optimization

1. Use `.select()` for granular provider updates
2. Implement provider caching with TTL
3. Reduce unnecessary widget rebuilds
4. Lazy-load heavy data

### UI Performance

1. Use `const` constructors everywhere
2. Implement `ListView.builder` for all lists
3. Add `RepaintBoundary` for complex widgets
4. Lazy load images and animations

### Memory Management

1. Properly dispose controllers and streams
2. Limit in-memory cache sizes
3. Use weak references where appropriate
4. Profile and fix memory leaks

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

## Application Evaluation Scores

| Category         | Score | Notes                                    |
| ---------------- | ----- | ---------------------------------------- |
| Architecture     | 9/10  | Clean Architecture, excellent separation |
| State Management | 9/10  | Riverpod with code generation            |
| Error Handling   | 9/10  | Type-safe Either pattern, undo stack     |
| Data Layer       | 9/10  | Offline-first, sync queue with retry     |
| UI/UX Components | 9/10  | Validated inputs, search, undo           |
| Documentation    | 7/10  | Strong architecture docs                 |
| Dependencies     | 8/10  | Modern, minimal bloat                    |
| Test Coverage    | 9/10  | 229 tests, 100% pass rate                |
| Performance      | 8/10  | Database indexed, fuzzy search optimized |
| Accessibility    | 6/10  | Semantic labels added                    |

**Overall: 8.3/10**

---

**Document Version**: 3.6
**Last Updated**: 2026-01-02
**Status**: Phase 15 In Progress - setState Migration Started (1/16 files complete, ~96% overall progress)

---

## Implementation Resources

See **`IMPLEMENTATION_GUIDE.md`** for detailed step-by-step instructions, code examples, and patterns for completing Phase 14 (Code Quality & Architecture) and Phase 15 (Advanced Refactoring) tasks.
