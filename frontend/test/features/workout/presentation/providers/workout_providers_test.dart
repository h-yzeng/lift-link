import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/providers/core_providers.dart';
import 'package:liftlink/core/services/streak_service.dart';
import 'package:liftlink/features/auth/domain/entities/user.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_history.dart';
import 'package:liftlink/features/workout/domain/entities/personal_record.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/usecases/get_active_workout.dart';
import 'package:liftlink/features/workout/domain/usecases/get_exercise_history.dart';
import 'package:liftlink/features/workout/domain/usecases/get_exercise_pr.dart';
import 'package:liftlink/features/workout/domain/usecases/get_personal_records.dart';
import 'package:liftlink/features/workout/domain/usecases/get_workout_history.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockGetActiveWorkout extends Mock implements GetActiveWorkout {}

class MockGetWorkoutHistory extends Mock implements GetWorkoutHistory {}

class MockGetExerciseHistory extends Mock implements GetExerciseHistory {}

class MockGetPersonalRecords extends Mock implements GetPersonalRecords {}

class MockGetExercisePR extends Mock implements GetExercisePR {}

class MockStreakService extends Mock implements StreakService {}

void main() {
  late MockGetActiveWorkout mockGetActiveWorkout;
  late MockGetWorkoutHistory mockGetWorkoutHistory;
  late MockGetExerciseHistory mockGetExerciseHistory;
  late MockGetPersonalRecords mockGetPersonalRecords;
  late MockGetExercisePR mockGetExercisePR;
  late MockStreakService mockStreakService;

  final testUser = User(
    id: 'test-user-id',
    email: 'test@example.com',
    createdAt: DateTime(2025, 1, 1),
  );

  final testWorkout = WorkoutSession(
    id: 'workout-1',
    userId: 'test-user-id',
    title: 'Test Workout',
    notes: null,
    startedAt: DateTime(2025, 1, 1, 10, 0),
    completedAt: null,
    durationMinutes: null,
    exercises: const [],
    createdAt: DateTime(2025, 1, 1, 10, 0),
    updatedAt: DateTime(2025, 1, 1, 10, 0),
  );

  final completedWorkouts = List.generate(
    10,
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

  setUp(() {
    mockGetActiveWorkout = MockGetActiveWorkout();
    mockGetWorkoutHistory = MockGetWorkoutHistory();
    mockGetExerciseHistory = MockGetExerciseHistory();
    mockGetPersonalRecords = MockGetPersonalRecords();
    mockGetExercisePR = MockGetExercisePR();
    mockStreakService = MockStreakService();
  });

  group('activeWorkout provider', () {
    test('should return active workout when user is authenticated', () async {
      // Arrange
      when(() => mockGetActiveWorkout(userId: testUser.id))
          .thenAnswer((_) async => Right(testWorkout));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getActiveWorkoutUseCaseProvider.overrideWithValue(mockGetActiveWorkout),
        ],
      );

      // Act
      final result = await container.read(activeWorkoutProvider.future);

      // Assert
      expect(result, testWorkout);
      verify(() => mockGetActiveWorkout(userId: testUser.id)).called(1);

      container.dispose();
    });

    test('should return null when user is not authenticated', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(null)),
          getActiveWorkoutUseCaseProvider.overrideWithValue(mockGetActiveWorkout),
        ],
      );

      // Act
      final result = await container.read(activeWorkoutProvider.future);

      // Assert
      expect(result, isNull);
      verifyNever(() => mockGetActiveWorkout(userId: any(named: 'userId')));

      container.dispose();
    });

    test('should return null when no active workout exists', () async {
      // Arrange
      when(() => mockGetActiveWorkout(userId: testUser.id))
          .thenAnswer((_) async => const Right(null));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getActiveWorkoutUseCaseProvider.overrideWithValue(mockGetActiveWorkout),
        ],
      );

      // Act
      final result = await container.read(activeWorkoutProvider.future);

      // Assert
      expect(result, isNull);

      container.dispose();
    });

    test('should throw exception when use case fails', () async {
      // Arrange
      when(() => mockGetActiveWorkout(userId: testUser.id)).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Database error')),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getActiveWorkoutUseCaseProvider.overrideWithValue(mockGetActiveWorkout),
        ],
      );

      // Act & Assert
      await expectLater(
        container.read(activeWorkoutProvider.future),
        throwsA(isA<Exception>()),
      );

      container.dispose();
    });
  });

  group('workoutHistory provider', () {
    test('should return workout history for authenticated user', () async {
      // Arrange
      when(() => mockGetWorkoutHistory(
            userId: testUser.id,
            limit: null,
            offset: null,
            startDate: null,
            endDate: null,
          ),).thenAnswer((_) async => Right(completedWorkouts));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
        ],
      );

      // Act
      final result = await container.read(workoutHistoryProvider().future);

      // Assert
      expect(result, completedWorkouts);
      verify(() => mockGetWorkoutHistory(
            userId: testUser.id,
            limit: null,
            offset: null,
            startDate: null,
            endDate: null,
          ),).called(1);

      container.dispose();
    });

    test('should return empty list when user is not authenticated', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(null)),
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
        ],
      );

      // Act
      final result = await container.read(workoutHistoryProvider().future);

      // Assert
      expect(result, isEmpty);
      verifyNever(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),);

      container.dispose();
    });

    test('should support pagination with limit and offset', () async {
      // Arrange
      final paginatedWorkouts = completedWorkouts.take(5).toList();
      when(() => mockGetWorkoutHistory(
            userId: testUser.id,
            limit: 5,
            offset: 10,
            startDate: null,
            endDate: null,
          ),).thenAnswer((_) async => Right(paginatedWorkouts));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
        ],
      );

      // Act
      final result = await container.read(
        workoutHistoryProvider(limit: 5, offset: 10).future,
      );

      // Assert
      expect(result.length, 5);
      verify(() => mockGetWorkoutHistory(
            userId: testUser.id,
            limit: 5,
            offset: 10,
            startDate: null,
            endDate: null,
          ),).called(1);

      container.dispose();
    });

    test('should support date filtering', () async {
      // Arrange
      final startDate = DateTime(2025, 1, 1);
      final endDate = DateTime(2025, 1, 31);
      final filteredWorkouts = completedWorkouts.take(3).toList();

      when(() => mockGetWorkoutHistory(
            userId: testUser.id,
            limit: null,
            offset: null,
            startDate: startDate,
            endDate: endDate,
          ),).thenAnswer((_) async => Right(filteredWorkouts));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
        ],
      );

      // Act
      final result = await container.read(
        workoutHistoryProvider(startDate: startDate, endDate: endDate).future,
      );

      // Assert
      expect(result.length, 3);
      verify(() => mockGetWorkoutHistory(
            userId: testUser.id,
            limit: null,
            offset: null,
            startDate: startDate,
            endDate: endDate,
          ),).called(1);

      container.dispose();
    });

    test('should throw exception when use case fails', () async {
      // Arrange
      when(() => mockGetWorkoutHistory(
            userId: testUser.id,
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Query failed')),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
        ],
      );

      // Act & Assert
      await expectLater(
        container.read(workoutHistoryProvider().future),
        throwsA(isA<Exception>()),
      );

      container.dispose();
    });
  });

  group('userWorkoutHistory provider', () {
    test('should return workout history for specified user', () async {
      // Arrange
      const otherUserId = 'other-user-id';
      when(() => mockGetWorkoutHistory(
            userId: otherUserId,
            limit: null,
            offset: null,
            startDate: null,
            endDate: null,
          ),).thenAnswer((_) async => Right(completedWorkouts));

      final container = ProviderContainer(
        overrides: [
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
        ],
      );

      // Act
      final result = await container.read(
        userWorkoutHistoryProvider(otherUserId).future,
      );

      // Assert
      expect(result, completedWorkouts);
      verify(() => mockGetWorkoutHistory(
            userId: otherUserId,
            limit: null,
            offset: null,
            startDate: null,
            endDate: null,
          ),).called(1);

      container.dispose();
    });

    test('should support limit and date filtering', () async {
      // Arrange
      const otherUserId = 'other-user-id';
      final startDate = DateTime(2025, 1, 1);
      final endDate = DateTime(2025, 1, 31);

      when(() => mockGetWorkoutHistory(
            userId: otherUserId,
            limit: 10,
            offset: null,
            startDate: startDate,
            endDate: endDate,
          ),).thenAnswer((_) async => Right(completedWorkouts));

      final container = ProviderContainer(
        overrides: [
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
        ],
      );

      // Act
      final result = await container.read(
        userWorkoutHistoryProvider(
          otherUserId,
          limit: 10,
          startDate: startDate,
          endDate: endDate,
        ).future,
      );

      // Assert
      expect(result, completedWorkouts);
      verify(() => mockGetWorkoutHistory(
            userId: otherUserId,
            limit: 10,
            offset: null,
            startDate: startDate,
            endDate: endDate,
          ),).called(1);

      container.dispose();
    });

    test('should throw exception when use case fails', () async {
      // Arrange
      const otherUserId = 'other-user-id';
      when(() => mockGetWorkoutHistory(
            userId: otherUserId,
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Query failed')),
      );

      final container = ProviderContainer(
        overrides: [
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
        ],
      );

      // Act & Assert
      await expectLater(
        container.read(userWorkoutHistoryProvider(otherUserId).future),
        throwsA(isA<Exception>()),
      );

      container.dispose();
    });
  });

  group('exerciseHistory provider', () {
    final testExerciseHistory = ExerciseHistory(
      exerciseId: 'exercise-1',
      userId: testUser.id,
      sessions: [
        ExerciseHistorySession(
          workoutSessionId: 'workout-1',
          workoutTitle: 'Test Workout',
          completedAt: DateTime(2025, 1, 1, 11, 0),
          sets: const [
            HistoricalSet(
              setNumber: 1,
              reps: 10,
              weightKg: 50.0,
              isWarmup: false,
            ),
            HistoricalSet(
              setNumber: 2,
              reps: 8,
              weightKg: 55.0,
              isWarmup: false,
            ),
          ],
        ),
      ],
    );

    test('should return exercise history for authenticated user', () async {
      // Arrange
      when(() => mockGetExerciseHistory(
            userId: testUser.id,
            exerciseId: 'exercise-1',
            limit: 3,
          ),).thenAnswer((_) async => Right(testExerciseHistory));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getExerciseHistoryUseCaseProvider
              .overrideWithValue(mockGetExerciseHistory),
        ],
      );

      // Act
      final result = await container.read(
        exerciseHistoryProvider(exerciseId: 'exercise-1').future,
      );

      // Assert
      expect(result, testExerciseHistory);
      verify(() => mockGetExerciseHistory(
            userId: testUser.id,
            exerciseId: 'exercise-1',
            limit: 3,
          ),).called(1);

      container.dispose();
    });

    test('should return empty history when user is not authenticated',
        () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(null)),
          getExerciseHistoryUseCaseProvider
              .overrideWithValue(mockGetExerciseHistory),
        ],
      );

      // Act
      final result = await container.read(
        exerciseHistoryProvider(exerciseId: 'exercise-1').future,
      );

      // Assert
      expect(result.exerciseId, 'exercise-1');
      expect(result.userId, '');
      expect(result.sessions, isEmpty);
      verifyNever(() => mockGetExerciseHistory(
            userId: any(named: 'userId'),
            exerciseId: any(named: 'exerciseId'),
            limit: any(named: 'limit'),
          ),);

      container.dispose();
    });

    test('should support custom limit parameter', () async {
      // Arrange
      when(() => mockGetExerciseHistory(
            userId: testUser.id,
            exerciseId: 'exercise-1',
            limit: 5,
          ),).thenAnswer((_) async => Right(testExerciseHistory));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getExerciseHistoryUseCaseProvider
              .overrideWithValue(mockGetExerciseHistory),
        ],
      );

      // Act
      final result = await container.read(
        exerciseHistoryProvider(exerciseId: 'exercise-1', limit: 5).future,
      );

      // Assert
      expect(result, testExerciseHistory);
      verify(() => mockGetExerciseHistory(
            userId: testUser.id,
            exerciseId: 'exercise-1',
            limit: 5,
          ),).called(1);

      container.dispose();
    });

    test('should throw exception when use case fails', () async {
      // Arrange
      when(() => mockGetExerciseHistory(
            userId: testUser.id,
            exerciseId: 'exercise-1',
            limit: any(named: 'limit'),
          ),).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Query failed')),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getExerciseHistoryUseCaseProvider
              .overrideWithValue(mockGetExerciseHistory),
        ],
      );

      // Act & Assert
      await expectLater(
        container.read(
          exerciseHistoryProvider(exerciseId: 'exercise-1').future,
        ),
        throwsA(isA<Exception>()),
      );

      container.dispose();
    });
  });

  group('personalRecords provider', () {
    final testRecords = <PersonalRecord>[
      PersonalRecord(
        exerciseId: 'exercise-1',
        exerciseName: 'Bench Press',
        userId: testUser.id,
        weight: 100.0,
        reps: 1,
        oneRepMax: 100.0,
        achievedAt: DateTime(2025, 1, 15),
        workoutId: 'workout-1',
      ),
      PersonalRecord(
        exerciseId: 'exercise-2',
        exerciseName: 'Squat',
        userId: testUser.id,
        weight: 150.0,
        reps: 5,
        oneRepMax: 175.0,
        achievedAt: DateTime(2025, 1, 10),
        workoutId: 'workout-2',
      ),
    ];

    test('should return personal records for authenticated user', () async {
      // Arrange
      when(() => mockGetPersonalRecords(userId: testUser.id))
          .thenAnswer((_) async => Right(testRecords));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getPersonalRecordsUseCaseProvider
              .overrideWithValue(mockGetPersonalRecords),
        ],
      );

      // Act
      final result = await container.read(personalRecordsProvider.future);

      // Assert
      expect(result, testRecords);
      verify(() => mockGetPersonalRecords(userId: testUser.id)).called(1);

      container.dispose();
    });

    test('should return empty list when user is not authenticated', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(null)),
          getPersonalRecordsUseCaseProvider
              .overrideWithValue(mockGetPersonalRecords),
        ],
      );

      // Act
      final result = await container.read(personalRecordsProvider.future);

      // Assert
      expect(result, isEmpty);
      verifyNever(
          () => mockGetPersonalRecords(userId: any(named: 'userId')),);

      container.dispose();
    });

    test('should throw exception when use case fails', () async {
      // Arrange
      when(() => mockGetPersonalRecords(userId: testUser.id)).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Query failed')),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getPersonalRecordsUseCaseProvider
              .overrideWithValue(mockGetPersonalRecords),
        ],
      );

      // Act & Assert
      await expectLater(
        container.read(personalRecordsProvider.future),
        throwsA(isA<Exception>()),
      );

      container.dispose();
    });
  });

  group('exercisePR provider', () {
    final testRecord = PersonalRecord(
      exerciseId: 'exercise-1',
      exerciseName: 'Bench Press',
      userId: testUser.id,
      weight: 100.0,
      reps: 1,
      oneRepMax: 100.0,
      achievedAt: DateTime(2025, 1, 15),
      workoutId: 'workout-1',
    );

    test('should return PR for specific exercise', () async {
      // Arrange
      when(() => mockGetExercisePR(
            userId: testUser.id,
            exerciseId: 'exercise-1',
          ),).thenAnswer((_) async => Right(testRecord));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getExercisePRUseCaseProvider.overrideWithValue(mockGetExercisePR),
        ],
      );

      // Act
      final result =
          await container.read(exercisePRProvider('exercise-1').future);

      // Assert
      expect(result, testRecord);
      verify(() => mockGetExercisePR(
            userId: testUser.id,
            exerciseId: 'exercise-1',
          ),).called(1);

      container.dispose();
    });

    test('should return null when user is not authenticated', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(null)),
          getExercisePRUseCaseProvider.overrideWithValue(mockGetExercisePR),
        ],
      );

      // Act
      final result =
          await container.read(exercisePRProvider('exercise-1').future);

      // Assert
      expect(result, isNull);
      verifyNever(() => mockGetExercisePR(
            userId: any(named: 'userId'),
            exerciseId: any(named: 'exerciseId'),
          ),);

      container.dispose();
    });

    test('should return null when no PR exists for exercise', () async {
      // Arrange
      when(() => mockGetExercisePR(
            userId: testUser.id,
            exerciseId: 'exercise-1',
          ),).thenAnswer((_) async => const Right(null));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getExercisePRUseCaseProvider.overrideWithValue(mockGetExercisePR),
        ],
      );

      // Act
      final result =
          await container.read(exercisePRProvider('exercise-1').future);

      // Assert
      expect(result, isNull);

      container.dispose();
    });

    test('should throw exception when use case fails', () async {
      // Arrange
      when(() => mockGetExercisePR(
            userId: testUser.id,
            exerciseId: 'exercise-1',
          ),).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Query failed')),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getExercisePRUseCaseProvider.overrideWithValue(mockGetExercisePR),
        ],
      );

      // Act & Assert
      await expectLater(
        container.read(exercisePRProvider('exercise-1').future),
        throwsA(isA<Exception>()),
      );

      container.dispose();
    });
  });

  group('workoutStreak provider', () {
    final testStreakData = StreakData(
      currentStreak: 5,
      longestStreak: 10,
      lastWorkoutDate: DateTime(2025, 1, 15, 11, 0),
    );

    test('should calculate streak for authenticated user', () async {
      // Arrange
      when(() => mockGetWorkoutHistory(
            userId: testUser.id,
            limit: 365,
            offset: null,
            startDate: null,
            endDate: null,
          ),).thenAnswer((_) async => Right(completedWorkouts));

      when(() => mockStreakService.calculateStreak(completedWorkouts))
          .thenReturn(testStreakData);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
          streakServiceProvider.overrideWithValue(mockStreakService),
        ],
      );

      // Act
      final result = await container.read(workoutStreakProvider.future);

      // Assert
      expect(result, testStreakData);
      verify(() => mockGetWorkoutHistory(
            userId: testUser.id,
            limit: 365,
            offset: null,
            startDate: null,
            endDate: null,
          ),).called(1);
      verify(() => mockStreakService.calculateStreak(completedWorkouts))
          .called(1);

      container.dispose();
    });

    test('should return zero streak when user is not authenticated', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(null)),
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
          streakServiceProvider.overrideWithValue(mockStreakService),
        ],
      );

      // Act
      final result = await container.read(workoutStreakProvider.future);

      // Assert
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(result.lastWorkoutDate, isNull);
      verifyNever(() => mockGetWorkoutHistory(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),);
      verifyNever(() => mockStreakService.calculateStreak(any()));

      container.dispose();
    });

    test('should handle empty workout history', () async {
      // Arrange
      when(() => mockGetWorkoutHistory(
            userId: testUser.id,
            limit: 365,
            offset: null,
            startDate: null,
            endDate: null,
          ),).thenAnswer((_) async => const Right([]));

      when(() => mockStreakService.calculateStreak([]))
          .thenReturn(const StreakData(
        currentStreak: 0,
        longestStreak: 0,
        lastWorkoutDate: null,
      ),);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          getWorkoutHistoryUseCaseProvider
              .overrideWithValue(mockGetWorkoutHistory),
          streakServiceProvider.overrideWithValue(mockStreakService),
        ],
      );

      // Act
      final result = await container.read(workoutStreakProvider.future);

      // Assert
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(result.lastWorkoutDate, isNull);

      container.dispose();
    });
  });
}
