import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
import 'package:liftlink/features/workout/domain/usecases/get_active_workout.dart';
import 'package:liftlink/features/workout/domain/usecases/get_workout_history.dart';
import 'package:liftlink/features/workout/domain/usecases/start_workout.dart';
import 'package:liftlink/features/workout/domain/usecases/update_set.dart';
import 'package:liftlink/features/workout/presentation/providers/exercise_providers.dart'
    hide networkInfoProvider;

part 'workout_providers.g.dart';

// Data source providers
@riverpod
WorkoutLocalDataSource workoutLocalDataSource(Ref ref) {
  return WorkoutLocalDataSourceImpl(
    database: ref.watch(appDatabaseProvider),
  );
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
  return AddExerciseToWorkout(ref.watch(workoutRepositoryProvider));
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
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];

  final useCase = ref.watch(getWorkoutHistoryUseCaseProvider);
  final result = await useCase(
    userId: user.id,
    limit: limit,
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
