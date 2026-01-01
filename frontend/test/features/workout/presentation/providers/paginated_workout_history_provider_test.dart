import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/domain/entities/user.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/usecases/get_workout_history.dart';
import 'package:liftlink/features/workout/presentation/providers/paginated_workout_history_provider.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockGetWorkoutHistory extends Mock implements GetWorkoutHistory {}

class FakeGetWorkoutHistoryParams extends Fake {}

void main() {
  late MockGetWorkoutHistory mockGetWorkoutHistory;
  late ProviderContainer container;

  setUp(() {
    mockGetWorkoutHistory = MockGetWorkoutHistory();

    container = ProviderContainer(
      overrides: [
        getWorkoutHistoryUseCaseProvider
            .overrideWithValue(mockGetWorkoutHistory),
        currentUserProvider.overrideWith(
          (ref) async => User(
            id: 'test-user-id',
            email: 'test@example.com',
            createdAt: DateTime(2025, 1, 1),
          ),
        ),
      ],
    );

    // Register fallback value for any() matcher
    registerFallbackValue(FakeGetWorkoutHistoryParams());
  });

  tearDown(() {
    container.dispose();
  });

  group('PaginatedWorkoutHistoryNotifier', () {
    final testWorkouts = List.generate(
      20,
      (index) => WorkoutSession(
        id: 'workout-$index',
        userId: 'test-user-id',
        title: 'Workout $index',
        notes: null,
        startedAt: DateTime(2025, 1, index + 1, 10, 0),
        completedAt: DateTime(2025, 1, index + 1, 11, 0),
        durationMinutes: 60,
        exercises: const [],
        createdAt: DateTime(2025, 1, index + 1, 10, 0),
        updatedAt: DateTime(2025, 1, index + 1, 11, 0),
      ),
    );

    test('should have correct initial state', () {
      // Act
      final state = container.read(paginatedWorkoutHistoryProvider);

      // Assert
      expect(state.workouts, isEmpty);
      expect(state.isLoading, false);
      expect(state.hasMore, true);
      expect(state.error, isNull);
      expect(state.currentPage, 0);
    });

    test('should load first page successfully', () async {
      // Arrange
      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => Right(testWorkouts));

      final notifier = container.read(paginatedWorkoutHistoryProvider.notifier);

      // Act
      await notifier.loadFirstPage();

      // Assert
      final state = container.read(paginatedWorkoutHistoryProvider);
      expect(state.workouts.length, 20);
      expect(state.isLoading, false);
      expect(state.hasMore, true);
      expect(state.error, isNull);
      expect(state.currentPage, 0);

      verify(() => mockGetWorkoutHistory(
            userId: 'test-user-id',
            limit: 20,
            offset: 0,
            startDate: null,
            endDate: null,
          ),).called(1);
    });

    test('should load first page with date filters', () async {
      // Arrange
      final startDate = DateTime(2025, 1, 1);
      final endDate = DateTime(2025, 1, 31);

      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => Right(testWorkouts.take(10).toList()));

      final notifier = container.read(paginatedWorkoutHistoryProvider.notifier);

      // Act
      await notifier.loadFirstPage(
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      final state = container.read(paginatedWorkoutHistoryProvider);
      expect(state.workouts.length, 10);
      expect(state.hasMore, false); // Less than 20 items

      verify(() => mockGetWorkoutHistory(
            userId: 'test-user-id',
            limit: 20,
            offset: 0,
            startDate: startDate,
            endDate: endDate,
          ),).called(1);
    });

    test('should load next page successfully', () async {
      // Arrange
      final firstPageWorkouts = testWorkouts.take(20).toList();
      final secondPageWorkouts = List.generate(
        20,
        (index) => WorkoutSession(
          id: 'workout-${20 + index}',
          userId: 'test-user-id',
          title: 'Workout ${20 + index}',
          notes: null,
          startedAt: DateTime(2025, 2, index + 1, 10, 0),
          completedAt: DateTime(2025, 2, index + 1, 11, 0),
          durationMinutes: 60,
          exercises: const [],
          createdAt: DateTime(2025, 2, index + 1, 10, 0),
          updatedAt: DateTime(2025, 2, index + 1, 11, 0),
        ),
      );

      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: 0,
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => Right(firstPageWorkouts));

      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: 20,
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => Right(secondPageWorkouts));

      final notifier = container.read(paginatedWorkoutHistoryProvider.notifier);

      // Load first page
      await notifier.loadFirstPage();

      // Act - Load next page
      await notifier.loadNextPage();

      // Assert
      final state = container.read(paginatedWorkoutHistoryProvider);
      expect(state.workouts.length, 40);
      expect(state.currentPage, 1);
      expect(state.hasMore, true);
      expect(state.isLoading, false);
      expect(state.error, isNull);

      verify(() => mockGetWorkoutHistory(
            userId: 'test-user-id',
            limit: 20,
            offset: 20,
            startDate: null,
            endDate: null,
          ),).called(1);
    });

    test('should set hasMore to false when receiving less than page size',
        () async {
      // Arrange
      final partialPage = testWorkouts.take(10).toList();
      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => Right(partialPage));

      final notifier = container.read(paginatedWorkoutHistoryProvider.notifier);

      // Act
      await notifier.loadFirstPage();

      // Assert
      final state = container.read(paginatedWorkoutHistoryProvider);
      expect(state.workouts.length, 10);
      expect(state.hasMore, false); // Less than 20 items
      expect(state.isLoading, false);
    });

    test('should not load next page when already loading', () async {
      // Arrange
      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Right(testWorkouts);
        },
      );

      final notifier = container.read(paginatedWorkoutHistoryProvider.notifier);
      await notifier.loadFirstPage();

      // Act - Try to load next page while loading
      final future1 = notifier.loadNextPage();
      final future2 = notifier.loadNextPage(); // Should be ignored

      await Future.wait([future1, future2]);

      // Assert - Should only call once for the next page (plus once for first page)
      verify(() => mockGetWorkoutHistory(
            userId: 'test-user-id',
            limit: 20,
            offset: any(named: 'offset'),
            startDate: null,
            endDate: null,
          ),).called(2); // Once for first page, once for next page
    });

    test('should not load next page when hasMore is false', () async {
      // Arrange
      final partialPage = testWorkouts.take(10).toList();
      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => Right(partialPage));

      final notifier = container.read(paginatedWorkoutHistoryProvider.notifier);
      await notifier.loadFirstPage();

      // Act - Try to load next page when hasMore is false
      await notifier.loadNextPage();

      // Assert - Should only call once for the first page
      verify(() => mockGetWorkoutHistory(
            userId: 'test-user-id',
            limit: 20,
            offset: any(named: 'offset'),
            startDate: null,
            endDate: null,
          ),).called(1);
    });

    test('should handle error when loading first page', () async {
      // Arrange
      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Database error')),
      );

      final notifier = container.read(paginatedWorkoutHistoryProvider.notifier);

      // Act
      await notifier.loadFirstPage();

      // Assert
      final state = container.read(paginatedWorkoutHistoryProvider);
      expect(state.workouts, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, 'Database error');
    });

    test('should handle error when loading next page', () async {
      // Arrange
      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: 0,
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => Right(testWorkouts));

      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: 20,
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Load more failed')),
      );

      final notifier = container.read(paginatedWorkoutHistoryProvider.notifier);
      await notifier.loadFirstPage();

      // Act
      await notifier.loadNextPage();

      // Assert
      final state = container.read(paginatedWorkoutHistoryProvider);
      expect(state.workouts.length, 20); // Still has first page data
      expect(state.isLoading, false);
      expect(state.error, 'Load more failed');
    });

    test('should refresh and reload with current date filters', () async {
      // Arrange
      final startDate = DateTime(2025, 1, 1);
      final endDate = DateTime(2025, 1, 31);

      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => Right(testWorkouts));

      final notifier = container.read(paginatedWorkoutHistoryProvider.notifier);

      // Load first page with filters
      await notifier.loadFirstPage(
        startDate: startDate,
        endDate: endDate,
      );

      // Act - Refresh
      await notifier.refresh();

      // Assert - Should call with same date filters
      verify(() => mockGetWorkoutHistory(
            userId: 'test-user-id',
            limit: 20,
            offset: 0,
            startDate: startDate,
            endDate: endDate,
          ),).called(2); // Once for initial load, once for refresh
    });

    test('should clear workouts when loading first page after previous data',
        () async {
      // Arrange
      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => Right(testWorkouts));

      final notifier = container.read(paginatedWorkoutHistoryProvider.notifier);

      // Load first page
      await notifier.loadFirstPage();
      expect(container.read(paginatedWorkoutHistoryProvider).workouts.length,
          20,);

      // Act - Load first page again (simulating a filter change)
      final newWorkouts = [testWorkouts.first];
      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => Right(newWorkouts));

      await notifier.loadFirstPage();

      // Assert - Should replace old data, not append
      final state = container.read(paginatedWorkoutHistoryProvider);
      expect(state.workouts.length, 1);
      expect(state.currentPage, 0);
      expect(state.hasMore, false);
    });

    test('should handle user not authenticated error', () async {
      // Arrange
      final unauthContainer = ProviderContainer(
        overrides: [
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
          currentUserProvider.overrideWith((ref) async => null),
        ],
      );

      final notifier =
          unauthContainer.read(paginatedWorkoutHistoryProvider.notifier);

      // Act
      await notifier.loadFirstPage();

      // Assert
      final state = unauthContainer.read(paginatedWorkoutHistoryProvider);
      expect(state.workouts, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, 'User not authenticated');
      expect(state.hasMore, false);

      unauthContainer.dispose();
    });

    test('should handle unexpected exceptions', () async {
      // Arrange
      when(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenThrow(Exception('Unexpected error'));

      final notifier = container.read(paginatedWorkoutHistoryProvider.notifier);

      // Act
      await notifier.loadFirstPage();

      // Assert
      final state = container.read(paginatedWorkoutHistoryProvider);
      expect(state.workouts, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, contains('Exception: Unexpected error'));
    });
  });

  group('PaginatedWorkoutHistoryState', () {
    test('should create state with default values', () {
      // Act
      const state = PaginatedWorkoutHistoryState(
        workouts: [],
        isLoading: false,
        hasMore: true,
      );

      // Assert
      expect(state.workouts, isEmpty);
      expect(state.isLoading, false);
      expect(state.hasMore, true);
      expect(state.error, isNull);
      expect(state.currentPage, 0);
    });

    test('should create state with custom values', () {
      // Arrange
      final workouts = [
        WorkoutSession(
          id: 'workout-1',
          userId: 'test-user-id',
          title: 'Test Workout',
          notes: null,
          startedAt: DateTime(2025, 1, 1, 10, 0),
          completedAt: DateTime(2025, 1, 1, 11, 0),
          durationMinutes: 60,
          exercises: const [],
          createdAt: DateTime(2025, 1, 1, 10, 0),
          updatedAt: DateTime(2025, 1, 1, 11, 0),
        ),
      ];

      // Act
      final state = PaginatedWorkoutHistoryState(
        workouts: workouts,
        isLoading: true,
        hasMore: false,
        error: 'Test error',
        currentPage: 2,
      );

      // Assert
      expect(state.workouts, workouts);
      expect(state.isLoading, true);
      expect(state.hasMore, false);
      expect(state.error, 'Test error');
      expect(state.currentPage, 2);
    });

    test('should copy state with new values', () {
      // Arrange
      const originalState = PaginatedWorkoutHistoryState(
        workouts: [],
        isLoading: false,
        hasMore: true,
      );

      // Act
      final newState = originalState.copyWith(
        isLoading: true,
        error: 'Error occurred',
      );

      // Assert
      expect(newState.workouts, isEmpty);
      expect(newState.isLoading, true);
      expect(newState.hasMore, true);
      expect(newState.error, 'Error occurred');
      expect(newState.currentPage, 0);
    });

    test('should preserve original values when copying with null', () {
      // Arrange
      final workouts = [
        WorkoutSession(
          id: 'workout-1',
          userId: 'test-user-id',
          title: 'Test Workout',
          notes: null,
          startedAt: DateTime(2025, 1, 1, 10, 0),
          completedAt: DateTime(2025, 1, 1, 11, 0),
          durationMinutes: 60,
          exercises: const [],
          createdAt: DateTime(2025, 1, 1, 10, 0),
          updatedAt: DateTime(2025, 1, 1, 11, 0),
        ),
      ];

      final originalState = PaginatedWorkoutHistoryState(
        workouts: workouts,
        isLoading: true,
        hasMore: false,
        error: 'Original error',
        currentPage: 3,
      );

      // Act
      final newState = originalState.copyWith();

      // Assert
      expect(newState.workouts, workouts);
      expect(newState.isLoading, true);
      expect(newState.hasMore, false);
      expect(newState.error, 'Original error');
      expect(newState.currentPage, 3);
    });
  });
}
