# LiftLink Architecture

## Overview

LiftLink follows **Clean Architecture** principles with a strict separation of concerns across three layers:

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

## Layers

### Presentation Layer
- **Responsibility**: UI components, state management, user interactions
- **Technology**: Flutter widgets, Riverpod providers
- **Rules**: Can depend on Domain layer, never directly on Data layer

### Domain Layer
- **Responsibility**: Business logic, entities, use cases
- **Technology**: Pure Dart (no Flutter dependencies)
- **Rules**: No dependencies on other layers - completely independent

### Data Layer
- **Responsibility**: Data fetching, persistence, external APIs
- **Technology**: Supabase (remote), Drift/SQLite (local)
- **Rules**: Implements interfaces defined in Domain layer

## Offline-First Architecture

LiftLink uses an **offline-first** approach where local data (Drift/SQLite) is the source of truth for the UI.

### Read Operations
```
User Request → Provider → Use Case → Repository
                                         ↓
                              ┌─────────────────────┐
                              │  Local Data Source  │ ← Always read from here
                              │     (Drift/SQLite)  │
                              └─────────────────────┘
                                         ↓
                              Background sync from Supabase (if online)
```

### Write Operations
```
User Action → Provider → Use Case → Repository
                                         ↓
                              ┌─────────────────────┐
                              │  Local Data Source  │ ← 1. Save locally first
                              │     (Drift/SQLite)  │
                              └─────────────────────┘
                                         ↓
                              ┌─────────────────────┐
                              │ Remote Data Source  │ ← 2. Sync to Supabase
                              │     (Supabase)      │    (if online)
                              └─────────────────────┘
                                         ↓
                              If offline: Mark as "pending sync"
```

### Sync Strategy
- **Pull**: Periodic background sync from Supabase to Drift
- **Push**: Immediate sync to Supabase when online
- **Conflict Resolution**: Last-write-wins based on `updated_at` timestamp
- **Pending Changes**: Tracked with `isPendingSync` flag in Drift

## Folder Structure

```
frontend/
├── lib/
│   ├── main.dart               # Entry point
│   ├── app.dart                # Root widget
│   │
│   ├── core/                   # Shared infrastructure
│   │   ├── config/             # Configuration (Supabase, etc.)
│   │   ├── constants/          # App constants
│   │   ├── error/              # Exceptions and Failures
│   │   └── network/            # Network connectivity
│   │
│   ├── features/               # Feature modules
│   │   ├── auth/
│   │   │   ├── presentation/   # Pages, widgets, providers
│   │   │   ├── domain/         # Entities, use cases, repository interfaces
│   │   │   └── data/           # Models, data sources, repository impl
│   │   ├── workout/
│   │   ├── social/
│   │   └── profile/
│   │
│   └── shared/                 # Shared components
│       ├── database/           # Drift database
│       └── widgets/            # Shared widgets
│
└── test/
    ├── unit/
    ├── widget/
    └── integration/
```

## Key Design Decisions

### 1. Type Safety with Freezed
All data classes use `freezed` for:
- Immutability
- Value equality
- Pattern matching
- JSON serialization

### 2. Calculated Properties (1RM)
The 1RM calculation is a **computed property**, not stored in the database:
```dart
double? get calculated1RM {
  if (isWarmup || weightKg <= 0 || reps <= 0) return null;
  return weightKg * (1 + reps / 30); // Epley Formula
}
```

### 3. Error Handling with Either
Repositories return `Either<Failure, Result>` for explicit error handling:
```dart
Future<Either<Failure, List<WorkoutSession>>> getWorkouts();
```

### 4. Riverpod for State Management
Using Riverpod with code generation for:
- Type-safe providers
- Automatic dependency injection
- Easy testing with overrides

### 5. Row Level Security
All data access is secured at the database level with Supabase RLS policies.

## Testing Strategy

- **Unit Tests**: Domain layer (entities, use cases)
- **Widget Tests**: Presentation layer (individual widgets)
- **Integration Tests**: Full feature flows
- **Mocking**: Data sources are easily mockable via interfaces
