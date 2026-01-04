# LiftLink - Implementation Guide

**Last Updated**: 2026-01-03  
**Status**: ✅ Active development guide  
**Purpose**: Practical patterns and examples for ongoing feature development

---

## Overview

This guide provides code patterns, best practices, and examples for implementing new features in LiftLink. All examples follow the established Clean Architecture with Riverpod state management.

---

## Quick Reference

### Project Architecture

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

### Development Commands

```bash
# Setup
cd frontend && flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Run
flutter run -d windows

# Test & Analyze
flutter test
flutter analyze

# Watch mode for code generation
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## Common Implementation Patterns

### 1. Adding a New Entity

**Step 1**: Create Drift table in `app_database.dart`

```dart
class ExampleTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Step 2**: Create Freezed entity in domain layer

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'example.freezed.dart';

@freezed
class Example with _$Example {
  const factory Example({
    required String id,
    required String userId,
    required String name,
    required int count,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Example;

  const Example._();

  // Computed properties
  bool get isActive => count > 0;
}
```

**Step 3**: Add database migration

```sql
-- migration file: 202XXXXXXXXXXX_add_example.sql
CREATE TABLE examples (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE examples ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own examples"
  ON examples FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own examples"
  ON examples FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

**Step 4**: Run code generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 2. Creating a Use Case

```dart
import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/example/domain/entities/example.dart';
import 'package:liftlink/features/example/domain/repositories/example_repository.dart';

class GetExampleById {
  final ExampleRepository repository;

  GetExampleById(this.repository);

  Future<Either<Failure, Example>> call({
    required String id,
  }) async {
    return await repository.getById(id);
  }
}
```

---

### 3. Creating a Repository

**Interface** (`domain/repositories/example_repository.dart`):

```dart
import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/example/domain/entities/example.dart';

abstract class ExampleRepository {
  Future<Either<Failure, Example>> getById(String id);
  Future<Either<Failure, List<Example>>> getAll(String userId);
  Future<Either<Failure, void>> create(Example example);
  Future<Either<Failure, void>> update(Example example);
  Future<Either<Failure, void>> delete(String id);
}
```

**Implementation** (`data/repositories/example_repository_impl.dart`):

```dart
import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/example/data/datasources/example_local_datasource.dart';
import 'package:liftlink/features/example/domain/entities/example.dart';
import 'package:liftlink/features/example/domain/repositories/example_repository.dart';

class ExampleRepositoryImpl implements ExampleRepository {
  final ExampleLocalDataSource localDataSource;

  ExampleRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Example>> getById(String id) async {
    try {
      final example = await localDataSource.getById(id);
      return Right(example);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Example>>> getAll(String userId) async {
    try {
      final examples = await localDataSource.getAll(userId);
      return Right(examples);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}
```

---

### 4. Creating Riverpod Providers

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/features/example/domain/entities/example.dart';
import 'package:liftlink/features/example/domain/repositories/example_repository.dart';

part 'example_providers.g.dart';

// Repository provider
@riverpod
ExampleRepository exampleRepository(ExampleRepositoryRef ref) {
  final localDataSource = ref.watch(exampleLocalDataSourceProvider);
  return ExampleRepositoryImpl(localDataSource: localDataSource);
}

// Use case provider
@riverpod
GetExampleById getExampleByIdUseCase(GetExampleByIdUseCaseRef ref) {
  return GetExampleById(ref.watch(exampleRepositoryProvider));
}

// Data provider
@riverpod
Future<Example> exampleById(ExampleByIdRef ref, String id) async {
  final useCase = ref.watch(getExampleByIdUseCaseProvider);
  final result = await useCase(id: id);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (example) => example,
  );
}

// List provider
@riverpod
Future<List<Example>> userExamples(UserExamplesRef ref, String userId) async {
  final repository = ref.watch(exampleRepositoryProvider);
  final result = await repository.getAll(userId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (examples) => examples,
  );
}
```

---

### 5. Creating a State Notifier (Complex State)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'example_state.freezed.dart';
part 'example_notifier.g.dart';

@freezed
class ExampleState with _$ExampleState {
  const factory ExampleState({
    @Default([]) List<Example> examples,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    Object? error,
  }) = _ExampleState;
}

@riverpod
class ExampleNotifier extends _$ExampleNotifier {
  static const _pageSize = 20;

  @override
  ExampleState build(String userId) {
    loadFirstPage();
    return const ExampleState();
  }

  Future<void> loadFirstPage() async {
    state = const ExampleState(isLoading: true);
    await _loadPage(offset: 0, isRefresh: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    await _loadPage(offset: state.examples.length);
  }

  Future<void> _loadPage({required int offset, bool isRefresh = false}) async {
    final repository = ref.read(exampleRepositoryProvider);
    final result = await repository.getAll(userId);

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure),
      (examples) => state = state.copyWith(
        examples: isRefresh ? examples : [...state.examples, ...examples],
        isLoading: false,
        hasMore: examples.length == _pageSize,
      ),
    );
  }
}
```

---

### 6. Widget Testing Pattern

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/example/presentation/pages/example_page.dart';

void main() {
  group('ExamplePage', () {
    testWidgets('displays loading state initially', (tester) async {
      final container = ProviderContainer(
        overrides: [
          userExamplesProvider('user1').overrideWith(
            (ref) => const AsyncValue.loading(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ExamplePage(userId: 'user1')),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays data when loaded', (tester) async {
      final testExamples = [
        Example(
          id: '1',
          userId: 'user1',
          name: 'Test',
          count: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          userExamplesProvider('user1').overrideWith(
            (ref) => AsyncValue.data(testExamples),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ExamplePage(userId: 'user1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
    });
  });
}
```

---

### 7. Accessibility Guidelines

Always add semantic labels to interactive elements:

```dart
// IconButton with semantic label
Semantics(
  label: 'Add example',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.add),
    onPressed: () => _addExample(),
    tooltip: 'Add Example',
  ),
)

// Decorative icons should be excluded
ExcludeSemantics(
  child: Icon(Icons.check_circle, color: Colors.green),
)
```

---

### 8. Database Migration Best Practices

1. **Never modify existing migrations** - always create new ones
2. **Test migrations locally** before deploying
3. **Include rollback logic** when possible
4. **Add indexes** for frequently queried columns
5. **Enable RLS** on all tables

Example migration with indexes:

```sql
-- Create table
CREATE TABLE examples (...);

-- Add indexes
CREATE INDEX idx_examples_user_id ON examples(user_id);
CREATE INDEX idx_examples_created_at ON examples(created_at DESC);

-- Composite index for common queries
CREATE INDEX idx_examples_user_created ON examples(user_id, created_at DESC);
```

---

### 9. Error Handling Pattern

```dart
// In UI layer
final exampleAsync = ref.watch(exampleByIdProvider(id));

return exampleAsync.when(
  data: (example) => _buildContent(example),
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => ErrorState(error: error.toString()),
);

// Or with AsyncValueBuilder from shared widgets
AsyncValueBuilder<Example>(
  value: exampleAsync,
  data: (example) => _buildContent(example),
)
```

---

### 10. Performance Optimization

**Use .select() for granular rebuilds:**

```dart
// Instead of watching entire state
final isLoading = ref.watch(exampleNotifierProvider.select((s) => s.isLoading));

// Instead of entire list
final count = ref.watch(userExamplesProvider('user1').select((list) => list.length));
```

**Add RepaintBoundary for expensive widgets:**

```dart
ListView.builder(
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: ExampleCard(example: examples[index]),
    );
  },
)
```

**Use const constructors everywhere possible:**

```dart
const Icon(Icons.check)
const EdgeInsets.all(16)
const SizedBox(height: 8)
```

---

## Recent Features (Phase 16)

### Plate Calculator Implementation

Key files:

- `lib/core/utils/plate_calculator.dart` - Calculation logic
- `lib/features/workout/presentation/widgets/plate_calculator_bottom_sheet.dart` - UI
- Integrated in `set_input_row.dart` with calculator button

**Pattern**: Utility class + modal bottom sheet widget

### Progressive Overload Suggestions

Key implementation in `exercise_list_section.dart`:

- Calculate 2.5% increase from previous workout average
- Display as badge with trending icon
- Considers minimum increments (2.5 lb / 1.25 kg)

**Pattern**: Enhanced existing widget with calculation logic

### Exercise Notes

Key files:

- Repository: `workout_repository.dart` - `updateExerciseNotes()` method
- Datasource: `workout_local_datasource.dart` - Drift update query
- UI: `exercise_list_section.dart` - TextField integration

**Pattern**: Full repository → datasource → UI flow

---

## Testing Guidelines

### Run Tests Before Committing

```bash
# All tests
flutter test

# Specific file
flutter test test/features/workout/domain/entities/workout_set_test.dart

# With coverage
flutter test --coverage
```

### Test Structure

1. **Unit tests**: Domain entities, use cases, utilities
2. **Widget tests**: Individual widgets, pages, flows
3. **Integration tests**: Full user journeys (if needed)

### Writing Good Tests

```dart
group('FeatureName', () {
  setUp(() {
    // Setup test data
  });

  tearDown(() {
    // Cleanup
  });

  test('should describe expected behavior', () {
    // Arrange
    final input = ...;

    // Act
    final result = ...;

    // Assert
    expect(result, expectedValue);
  });
});
```

---

## Code Quality Checklist

Before committing:

- [ ] Run `flutter analyze` → 0 issues
- [ ] Run `flutter test` → all passing
- [ ] Add trailing commas to multi-line parameters
- [ ] Use `const` constructors where possible
- [ ] Add semantic labels to IconButtons
- [ ] Dispose controllers in `dispose()`
- [ ] Handle error states in UI
- [ ] Update documentation if needed

---

## Common Issues & Solutions

### Issue: "Bad state: No element"

**Cause**: Accessing `.first` or `.single` on empty list  
**Solution**: Use `.firstOrNull` or check `.isEmpty` first

### Issue: "setState called after dispose"

**Cause**: Async operation completes after widget disposed  
**Solution**: Check `mounted` before setState, or use Riverpod

### Issue: Code generation not updating

**Solution**:

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Tests failing with "Null check operator"

**Cause**: Missing Mocktail fallback values  
**Solution**: Register fallbacks in `setUpAll`:

```dart
setUpAll(() {
  registerFallbackValue(FakeExample());
});
```

---

## Resources

- **Architecture Docs**: `docs/architecture.md`
- **Database Schema**: `docs/database-schema.md`
- **Task Tracking**: `docs/task.md`
- **Planning**: `docs/planning.md`

---

**Document Version**: 4.0  
**Last Updated**: 2026-01-03  
**Maintained For**: Active development and new feature implementation

---

## Key Established Patterns

The following patterns are established in the codebase and can be referenced:

- **EntityMerger**: Conflict resolution (`lib/core/sync/entity_merger.dart`)
- **Paginated Providers**: Freezed state with pagination (`lib/features/social/presentation/providers/`)
- **Widget Decomposition**: Large pages split into sections (`lib/features/workout/presentation/widgets/active_workout/`)
- **Test Helpers**: Reusable test utilities (`test/test_helpers/`)

---

## End of Guide
