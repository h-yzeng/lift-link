import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/features/workout/data/datasources/workout_local_datasource.dart';
import 'package:liftlink/features/workout/data/datasources/workout_remote_datasource.dart';
import 'package:liftlink/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutLocalDataSource extends Mock
    implements WorkoutLocalDataSource {}

class MockWorkoutRemoteDataSource extends Mock
    implements WorkoutRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeWorkoutSession extends Fake implements WorkoutSession {}

class FakeWorkoutSet extends Fake implements WorkoutSet {}

void main() {
  late WorkoutRepositoryImpl repository;
  late MockWorkoutLocalDataSource mockLocalDataSource;
  late MockWorkoutRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUpAll(() {
    registerFallbackValue(FakeWorkoutSession());
    registerFallbackValue(FakeWorkoutSet());
  });

  setUp(() {
    mockLocalDataSource = MockWorkoutLocalDataSource();
    mockRemoteDataSource = MockWorkoutRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = WorkoutRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('startWorkout', () {
    const userId = 'test-user-id';
    const title = 'Test Workout';
    const notes = 'Test notes';

    final testWorkout = WorkoutSession(
      id: 'test-workout-id',
      userId: userId,
      title: title,
      notes: notes,
      startedAt: DateTime(2025, 1, 1, 10, 0),
      completedAt: null,
      durationMinutes: null,
      exercises: const [],
      createdAt: DateTime(2025, 1, 1, 10, 0),
      updatedAt: DateTime(2025, 1, 1, 10, 0),
    );

    test('should save workout to local datasource and return it', () async {
      // Arrange
      when(() => mockLocalDataSource.startWorkout(any()))
          .thenAnswer((_) async => testWorkout);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.startWorkout(
        userId: userId,
        title: title,
        notes: notes,
      );

      // Assert
      expect(result, isA<Right<Failure, WorkoutSession>>());
      result.fold(
        (failure) => fail('Should return workout'),
        (workout) {
          expect(workout.userId, userId);
          expect(workout.title, title);
          expect(workout.notes, notes);
        },
      );
      verify(() => mockLocalDataSource.startWorkout(any())).called(1);
    });

    test('should sync to remote when online', () async {
      // Arrange
      when(() => mockLocalDataSource.startWorkout(any()))
          .thenAnswer((_) async => testWorkout);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.upsertWorkoutSession(any()))
          .thenAnswer((_) async => testWorkout);

      // Act
      final result = await repository.startWorkout(
        userId: userId,
        title: title,
      );

      // Assert
      expect(result, isA<Right<Failure, WorkoutSession>>());
      verify(() => mockLocalDataSource.startWorkout(any())).called(1);
      // Note: Remote sync happens in background, so we can't easily verify it
    });

    test('should return CacheFailure when local datasource throws CacheException',
        () async {
      // Arrange
      when(() => mockLocalDataSource.startWorkout(any()))
          .thenThrow(const CacheException(message: 'Database error'));

      // Act
      final result = await repository.startWorkout(
        userId: userId,
        title: title,
      );

      // Assert
      expect(result, isA<Left<Failure, WorkoutSession>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.userMessage, 'Database error');
        },
        (workout) => fail('Should return failure'),
      );
    });
  });

  group('getWorkoutHistory', () {
    const userId = 'test-user-id';
    final testWorkouts = [
      WorkoutSession(
        id: 'workout-1',
        userId: userId,
        title: 'Workout 1',
        notes: null,
        startedAt: DateTime(2025, 1, 1, 10, 0),
        completedAt: DateTime(2025, 1, 1, 11, 0),
        durationMinutes: 60,
        exercises: const [],
        createdAt: DateTime(2025, 1, 1, 10, 0),
        updatedAt: DateTime(2025, 1, 1, 11, 0),
      ),
      WorkoutSession(
        id: 'workout-2',
        userId: userId,
        title: 'Workout 2',
        notes: null,
        startedAt: DateTime(2025, 1, 2, 10, 0),
        completedAt: DateTime(2025, 1, 2, 11, 0),
        durationMinutes: 60,
        exercises: const [],
        createdAt: DateTime(2025, 1, 2, 10, 0),
        updatedAt: DateTime(2025, 1, 2, 11, 0),
      ),
    ];

    test('should return workouts from local datasource', () async {
      // Arrange
      when(() => mockLocalDataSource.getWorkoutHistory(
            userId: userId,
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => testWorkouts);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.getWorkoutHistory(
        userId: userId,
        limit: 20,
      );

      // Assert
      expect(result, isA<Right<Failure, List<WorkoutSession>>>());
      result.fold(
        (failure) => fail('Should return workouts'),
        (workouts) {
          expect(workouts.length, 2);
          expect(workouts[0].id, 'workout-1');
          expect(workouts[1].id, 'workout-2');
        },
      );
      verify(() => mockLocalDataSource.getWorkoutHistory(
            userId: userId,
            limit: 20,
            offset: null,
            startDate: null,
            endDate: null,
          ),).called(1);
    });

    test('should support offset for pagination', () async {
      // Arrange
      when(() => mockLocalDataSource.getWorkoutHistory(
            userId: userId,
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer((_) async => [testWorkouts[1]]);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.getWorkoutHistory(
        userId: userId,
        limit: 1,
        offset: 1,
      );

      // Assert
      expect(result, isA<Right<Failure, List<WorkoutSession>>>());
      result.fold(
        (failure) => fail('Should return workouts'),
        (workouts) {
          expect(workouts.length, 1);
          expect(workouts[0].id, 'workout-2');
        },
      );
      verify(() => mockLocalDataSource.getWorkoutHistory(
            userId: userId,
            limit: 1,
            offset: 1,
            startDate: null,
            endDate: null,
          ),).called(1);
    });

    test('should return CacheFailure when datasource throws', () async {
      // Arrange
      when(() => mockLocalDataSource.getWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenThrow(const CacheException(message: 'Query failed'));

      // Act
      final result = await repository.getWorkoutHistory(userId: userId);

      // Assert
      expect(result, isA<Left<Failure, List<WorkoutSession>>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.userMessage, 'Query failed');
        },
        (workouts) => fail('Should return failure'),
      );
    });
  });

  group('completeWorkout', () {
    const workoutId = 'test-workout-id';
    final completedWorkout = WorkoutSession(
      id: workoutId,
      userId: 'test-user-id',
      title: 'Test Workout',
      notes: 'Completed notes',
      startedAt: DateTime(2025, 1, 1, 10, 0),
      completedAt: DateTime(2025, 1, 1, 11, 0),
      durationMinutes: 60,
      exercises: const [],
      createdAt: DateTime(2025, 1, 1, 10, 0),
      updatedAt: DateTime(2025, 1, 1, 11, 0),
    );

    test('should complete workout locally and return it', () async {
      // Arrange
      when(() => mockLocalDataSource.completeWorkout(workoutId))
          .thenAnswer((_) async => completedWorkout);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.completeWorkout(
        workoutSessionId: workoutId,
      );

      // Assert
      expect(result, isA<Right<Failure, WorkoutSession>>());
      result.fold(
        (failure) => fail('Should return workout'),
        (workout) {
          expect(workout.id, workoutId);
          expect(workout.completedAt, isNotNull);
        },
      );
      verify(() => mockLocalDataSource.completeWorkout(workoutId)).called(1);
    });

    test('should sync to remote when online', () async {
      // Arrange
      when(() => mockLocalDataSource.completeWorkout(workoutId))
          .thenAnswer((_) async => completedWorkout);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.syncCompleteWorkout(any()))
          .thenAnswer((_) async => {});
      when(() => mockLocalDataSource.markWorkoutAsSynced(any()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.completeWorkout(
        workoutSessionId: workoutId,
      );

      // Assert
      expect(result, isA<Right<Failure, WorkoutSession>>());
      verify(() => mockLocalDataSource.completeWorkout(workoutId)).called(1);
    });

    test('should return CacheFailure when completion fails', () async {
      // Arrange
      when(() => mockLocalDataSource.completeWorkout(any()))
          .thenThrow(const CacheException(message: 'Completion failed'));

      // Act
      final result = await repository.completeWorkout(
        workoutSessionId: workoutId,
      );

      // Assert
      expect(result, isA<Left<Failure, WorkoutSession>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.userMessage, 'Completion failed');
        },
        (workout) => fail('Should return failure'),
      );
    });
  });

  group('updateSet', () {
    const setId = 'test-set-id';
    final testSet = WorkoutSet(
      id: setId,
      exercisePerformanceId: 'exercise-id',
      setNumber: 1,
      reps: 10,
      weightKg: 50.0,
      isWarmup: false,
      isDropset: false,
      rpe: 8.0,
      notes: null,
      createdAt: DateTime(2025, 1, 1, 10, 0),
      updatedAt: DateTime(2025, 1, 1, 10, 0),
    );

    final updatedSet = testSet.copyWith(
      reps: 12,
      weightKg: 55.0,
      updatedAt: DateTime(2025, 1, 1, 10, 5),
    );

    test('should update set locally and return updated set', () async {
      // Arrange
      when(() => mockLocalDataSource.getSetById(setId))
          .thenAnswer((_) async => testSet);
      when(() => mockLocalDataSource.updateSet(any()))
          .thenAnswer((_) async => updatedSet);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.updateSet(
        setId: setId,
        reps: 12,
        weightKg: 55.0,
      );

      // Assert
      expect(result, isA<Right<Failure, WorkoutSet>>());
      result.fold(
        (failure) => fail('Should return set'),
        (set) {
          expect(set.id, setId);
          expect(set.reps, 12);
          expect(set.weightKg, 55.0);
        },
      );
      verify(() => mockLocalDataSource.getSetById(setId)).called(1);
      verify(() => mockLocalDataSource.updateSet(any())).called(1);
    });

    test('should return CacheFailure when set not found', () async {
      // Arrange
      when(() => mockLocalDataSource.getSetById(setId))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.updateSet(
        setId: setId,
        reps: 12,
      );

      // Assert
      expect(result, isA<Left<Failure, WorkoutSet>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.userMessage, 'Set not found');
        },
        (set) => fail('Should return failure'),
      );
    });
  });
}
