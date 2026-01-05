import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:liftlink/core/caching/cache_provider.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/workout/data/datasources/workout_local_datasource.dart';
import 'package:liftlink/features/workout/data/datasources/workout_remote_datasource.dart';
import 'package:liftlink/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';
import 'package:liftlink/features/workout/domain/usecases/add_exercise_to_workout.dart';
import 'package:liftlink/features/workout/domain/usecases/add_set_to_exercise.dart';
import 'package:liftlink/features/workout/domain/usecases/complete_workout.dart';
import 'package:liftlink/features/workout/domain/usecases/delete_set.dart';
import 'package:liftlink/features/workout/domain/usecases/get_active_workout.dart';
import 'package:liftlink/features/workout/domain/usecases/get_exercise_history.dart';
import 'package:liftlink/features/workout/domain/usecases/get_workout_history.dart';
import 'package:liftlink/features/workout/domain/usecases/start_workout.dart';
import 'package:liftlink/features/workout/domain/usecases/update_set.dart';
import 'package:liftlink/features/workout/domain/usecases/get_personal_records.dart';
import 'package:liftlink/features/workout/domain/usecases/get_exercise_pr.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_history.dart';
import 'package:liftlink/features/workout/domain/entities/personal_record.dart';
import 'package:liftlink/features/workout/presentation/providers/exercise_providers.dart'
    as ex;
import 'package:liftlink/core/providers/core_providers.dart';
import 'package:liftlink/core/services/streak_service.dart';
import 'package:liftlink/shared/database/database_provider.dart';

part 'workout_providers.g.dart';

// Data source providers
@riverpod
WorkoutLocalDataSource workoutLocalDataSource(Ref ref) {
  return WorkoutLocalDataSourceImpl(database: ref.watch(databaseProvider));
}

@riverpod
WorkoutRemoteDataSource workoutRemoteDataSource(Ref ref) {
  return WorkoutRemoteDataSourceImpl(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
}

// Repository provider
@riverpod
WorkoutRepository workoutRepository(Ref ref) {
  return WorkoutRepositoryImpl(
    localDataSource: ref.watch(workoutLocalDataSourceProvider),
    remoteDataSource: ref.watch(workoutRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    cacheManager: ref.watch(cacheManagerProvider),
  );
}

// Use case providers
@riverpod
StartWorkout startWorkoutUseCase(Ref ref) {
  return StartWorkout(ref.watch(workoutRepositoryProvider));
}

@riverpod
GetActiveWorkout getActiveWorkoutUseCase(Ref ref) {
  return GetActiveWorkout(ref.watch(workoutRepositoryProvider));
}

@riverpod
AddExerciseToWorkout addExerciseToWorkoutUseCase(Ref ref) {
  return AddExerciseToWorkout(
    workoutRepository: ref.watch(workoutRepositoryProvider),
    exerciseRepository: ref.watch(ex.exerciseRepositoryProvider),
  );
}

@riverpod
AddSetToExercise addSetToExerciseUseCase(Ref ref) {
  return AddSetToExercise(ref.watch(workoutRepositoryProvider));
}

@riverpod
CompleteWorkout completeWorkoutUseCase(Ref ref) {
  return CompleteWorkout(ref.watch(workoutRepositoryProvider));
}

@riverpod
GetWorkoutHistory getWorkoutHistoryUseCase(Ref ref) {
  return GetWorkoutHistory(ref.watch(workoutRepositoryProvider));
}

@riverpod
UpdateSet updateSetUseCase(Ref ref) {
  return UpdateSet(ref.watch(workoutRepositoryProvider));
}

@riverpod
DeleteSet deleteSetUseCase(Ref ref) {
  return DeleteSet(ref.watch(workoutRepositoryProvider));
}

@riverpod
GetExerciseHistory getExerciseHistoryUseCase(Ref ref) {
  return GetExerciseHistory(ref.watch(workoutRepositoryProvider));
}

// Active workout provider - streams the current active workout
@riverpod
Future<WorkoutSession?> activeWorkout(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;

  final useCase = ref.watch(getActiveWorkoutUseCaseProvider);
  final result = await useCase(userId: user.id);

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (workout) => workout,
  );
}

// Workout history provider
@riverpod
Future<List<WorkoutSession>> workoutHistory(
  Ref ref, {
  int? limit,
  int? offset,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];

  final useCase = ref.watch(getWorkoutHistoryUseCaseProvider);
  final result = await useCase(
    userId: user.id,
    limit: limit,
    offset: offset,
    startDate: startDate,
    endDate: endDate,
  );

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (workouts) => workouts,
  );
}

// User workout history provider - fetches workouts for a specific user
@riverpod
Future<List<WorkoutSession>> userWorkoutHistory(
  Ref ref,
  String userId, {
  int? limit,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final useCase = ref.watch(getWorkoutHistoryUseCaseProvider);
  final result = await useCase(
    userId: userId,
    limit: limit,
    startDate: startDate,
    endDate: endDate,
  );

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (workouts) => workouts,
  );
}

// Exercise history provider - gets history for a specific exercise
@riverpod
Future<ExerciseHistory> exerciseHistory(
  Ref ref, {
  required String exerciseId,
  int limit = 3,
}) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    return ExerciseHistory(
      exerciseId: exerciseId,
      userId: '',
      sessions: const [],
    );
  }

  final useCase = ref.watch(getExerciseHistoryUseCaseProvider);
  final result = await useCase(
    userId: user.id,
    exerciseId: exerciseId,
    limit: limit,
  );

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (history) => history,
  );
}

// Personal Records use case providers
@riverpod
GetPersonalRecords getPersonalRecordsUseCase(Ref ref) {
  return GetPersonalRecords(ref.watch(workoutRepositoryProvider));
}

@riverpod
GetExercisePR getExercisePRUseCase(Ref ref) {
  return GetExercisePR(ref.watch(getPersonalRecordsUseCaseProvider));
}

// Personal records provider - gets all PRs for current user
@riverpod
Future<List<PersonalRecord>> personalRecords(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];

  final useCase = ref.watch(getPersonalRecordsUseCaseProvider);
  final result = await useCase(userId: user.id);

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (records) => records,
  );
}

// Exercise PR provider - gets PR for a specific exercise
@riverpod
Future<PersonalRecord?> exercisePR(Ref ref, String exerciseId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;

  final useCase = ref.watch(getExercisePRUseCaseProvider);
  final result = await useCase(userId: user.id, exerciseId: exerciseId);

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (record) => record,
  );
}

// Workout streak provider - calculates current and longest streaks
@riverpod
Future<StreakData> workoutStreak(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    return const StreakData(
      currentStreak: 0,
      longestStreak: 0,
      lastWorkoutDate: null,
    );
  }

  // Get all completed workouts
  final workouts = await ref.watch(
    workoutHistoryProvider(limit: 365).future, // Look back up to 1 year
  );

  // Use StreakService to calculate streak
  final streakService = ref.watch(streakServiceProvider);
  return streakService.calculateStreak(workouts);
}
