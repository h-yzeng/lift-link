import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:liftlink/core/caching/cache_manager.dart';
import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/features/workout/data/datasources/workout_local_datasource.dart';
import 'package:liftlink/features/workout/data/datasources/workout_remote_datasource.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_history.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Implementation of [WorkoutRepository] with caching support.
///
/// This repository follows an offline-first approach, reading from local storage
/// and syncing with remote storage in the background. Query results are cached
/// to reduce database operations and improve performance.
class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutLocalDataSource localDataSource;
  final WorkoutRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final CacheManager cacheManager;

  WorkoutRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.cacheManager,
  });

  @override
  Future<Either<Failure, WorkoutSession>> startWorkout({
    required String userId,
    required String title,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final session = WorkoutSession(
        id: const Uuid().v4(),
        userId: userId,
        title: title,
        notes: notes,
        startedAt: now,
        completedAt: null,
        durationMinutes: null,
        exercises: const [],
        createdAt: now,
        updatedAt: now,
      );

      // Save to local first (offline-first)
      final savedSession = await localDataSource.startWorkout(session);

      // Sync to remote in background if online
      if (await networkInfo.isConnected) {
        _syncInBackground(() async {
          await remoteDataSource.upsertWorkoutSession(savedSession);
        });
      }

      return Right(savedSession);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkoutSession?>> getActiveWorkout({
    required String userId,
  }) async {
    try {
      final session = await localDataSource.getActiveWorkout(userId);
      return Right(session);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExercisePerformance>> addExerciseToWorkout({
    required String workoutSessionId,
    required String exerciseId,
    required String exerciseName,
    int? orderIndex,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();

      // Determine order index if not provided
      final effectiveOrderIndex =
          orderIndex ?? await _getNextExerciseOrderIndex(workoutSessionId);

      final performance = ExercisePerformance(
        id: const Uuid().v4(),
        workoutSessionId: workoutSessionId,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        orderIndex: effectiveOrderIndex,
        notes: notes,
        sets: const [],
        createdAt: now,
        updatedAt: now,
      );

      // Save to local first
      final savedPerformance =
          await localDataSource.addExerciseToWorkout(performance);

      // Mark workout as pending sync
      await _markWorkoutPendingSync(workoutSessionId);

      // Sync to remote in background
      if (await networkInfo.isConnected) {
        _syncInBackground(() async {
          await remoteDataSource.upsertExercisePerformance(savedPerformance);
        });
      }

      return Right(savedPerformance);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkoutSet>> addSetToExercise({
    required String exercisePerformanceId,
    required int setNumber,
    required int reps,
    required double weightKg,
    bool isWarmup = false,
    bool isDropset = false,
    double? rpe,
    int? rir,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final set = WorkoutSet(
        id: const Uuid().v4(),
        exercisePerformanceId: exercisePerformanceId,
        setNumber: setNumber,
        reps: reps,
        weightKg: weightKg,
        isWarmup: isWarmup,
        isDropset: isDropset,
        rpe: rpe,
        rir: rir,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      // Save to local first
      final savedSet = await localDataSource.addSetToExercise(set);

      // Sync to remote in background
      if (await networkInfo.isConnected) {
        _syncInBackground(() async {
          await remoteDataSource.upsertSet(savedSet);
        });
      }

      return Right(savedSet);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkoutSet>> updateSet({
    required String setId,
    int? reps,
    double? weightKg,
    bool? isWarmup,
    bool? isDropset,
    double? rpe,
    int? rir,
    String? notes,
  }) async {
    try {
      // Get the current set from database
      final currentSet = await localDataSource.getSetById(setId);
      if (currentSet == null) {
        return const Left(CacheFailure(message: 'Set not found'));
      }

      // Create updated set with new values (keep existing values for null params)
      final updatedSet = currentSet.copyWith(
        reps: reps ?? currentSet.reps,
        weightKg: weightKg ?? currentSet.weightKg,
        isWarmup: isWarmup ?? currentSet.isWarmup,
        isDropset: isDropset ?? currentSet.isDropset,
        rpe: rpe ?? currentSet.rpe,
        rir: rir ?? currentSet.rir,
        notes: notes ?? currentSet.notes,
        updatedAt: DateTime.now(),
      );

      // Update in local database
      final savedSet = await localDataSource.updateSet(updatedSet);

      // Sync to remote in background
      if (await networkInfo.isConnected) {
        _syncInBackground(() async {
          await remoteDataSource.upsertSet(savedSet);
        });
      }

      return Right(savedSet);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeSet(String setId) async {
    try {
      await localDataSource.removeSet(setId);

      // Note: Remote sync will happen when workout is completed or manually synced
      // For now, we just mark the workout as pending sync

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeExercise(
    String exercisePerformanceId,
  ) async {
    try {
      await localDataSource.removeExercise(exercisePerformanceId);

      // Note: Remote sync will happen when workout is completed or manually synced

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateExerciseNotes({
    required String exercisePerformanceId,
    String? notes,
  }) async {
    try {
      await localDataSource.updateExerciseNotes(
        exercisePerformanceId: exercisePerformanceId,
        notes: notes,
      );

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkoutSession>> completeWorkout({
    required String workoutSessionId,
    String? notes,
  }) async {
    try {
      // Complete the workout locally
      final completedWorkout = await localDataSource.completeWorkout(
        workoutSessionId: workoutSessionId,
        notes: notes,
      );

      // Invalidate workout history caches
      cacheManager
          .invalidatePattern('workout_history_${completedWorkout.userId}');
      // Invalidate exercise history caches for all exercises in this workout
      for (final exercise in completedWorkout.exercises) {
        cacheManager.invalidatePattern(
            'exercise_history_${completedWorkout.userId}_${exercise.exerciseId}');
      }
      final completedWorkout =
          await localDataSource.completeWorkout(workoutSessionId);

      // Update notes if provided
      if (notes != null && notes != completedWorkout.notes) {
        final updatedWorkout = completedWorkout.copyWith(notes: notes);
        await localDataSource.upsertWorkoutSession(updatedWorkout);
      }

      // Sync complete workout to remote if online
      if (await networkInfo.isConnected) {
        _syncInBackground(() async {
          await remoteDataSource.syncCompleteWorkout(completedWorkout);
          await localDataSource.markWorkoutAsSynced(workoutSessionId);
        });
      }

      return Right(completedWorkout);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkoutSession>> getWorkoutById(String id) async {
    try {
      final workout = await localDataSource.getWorkoutById(id);
      return Right(workout);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WorkoutSession>>> getWorkoutHistory({
    required String userId,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Generate cache key based on parameters
      final cacheKey = 'workout_history_$userId'
          '_${limit ?? 'all'}_${offset ?? '0'}'
          '_${startDate?.millisecondsSinceEpoch ?? 'any'}'
          '_${endDate?.millisecondsSinceEpoch ?? 'any'}';

      // Check cache first
      final cachedWorkouts = cacheManager.get<List<WorkoutSession>>(cacheKey);
      if (cachedWorkouts != null) {
        return Right(cachedWorkouts);
      }

      // Always read from local (offline-first)
      final workouts = await localDataSource.getWorkoutHistory(
        userId: userId,
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      );

      // Cache result for 5 minutes
      cacheManager.set(cacheKey, workouts, const Duration(minutes: 5));

      // Sync from remote in background if online
      if (await networkInfo.isConnected) {
        _syncInBackground(() async {
          await syncWorkouts(userId: userId);
          // Invalidate cache after sync to get fresh data
          cacheManager.invalidatePattern('workout_history_$userId');
        });
      }

      return Right(workouts);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExerciseHistory>> getExerciseHistory({
    required String userId,
    required String exerciseId,
    int limit = 3,
  }) async {
    try {
      // Generate cache key
      final cacheKey = 'exercise_history_${userId}_${exerciseId}_$limit';

      // Check cache first
      final cachedHistory = cacheManager.get<ExerciseHistory>(cacheKey);
      if (cachedHistory != null) {
        return Right(cachedHistory);
      }

      // Always read from local (offline-first)
      final history = await localDataSource.getExerciseHistory(
        userId: userId,
        exerciseId: exerciseId,
        limit: limit,
      );

      // Cache result for 3 minutes
      cacheManager.set(cacheKey, history, const Duration(minutes: 3));

      return Right(history);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncWorkouts({String? userId}) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      if (userId == null) {
        return const Right(null);
      }

      // Sync pending local workouts to remote
      final pendingWorkouts =
          await localDataSource.getPendingSyncWorkouts(userId);

      for (final workout in pendingWorkouts) {
        await remoteDataSource.syncCompleteWorkout(workout);
        await localDataSource.markWorkoutAsSynced(workout.id);
      }

      // Fetch remote workouts and update local
      final remoteWorkouts = await remoteDataSource.fetchWorkouts(
        userId: userId,
        limit: 100, // Fetch last 100 workouts
      );

      for (final workout in remoteWorkouts) {
        await localDataSource.upsertWorkoutSession(workout);
        for (final exercise in workout.exercises) {
          await localDataSource.upsertExercisePerformance(exercise);
          for (final set in exercise.sets) {
            await localDataSource.upsertSet(set);
          }
        }
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Fire and forget background sync
  void _syncInBackground(Future<void> Function() syncFn) {
    syncFn().catchError((_) {
      // Silently fail - sync will happen later
    });
  }

  /// Helper to get the next order index for an exercise in a workout
  Future<int> _getNextExerciseOrderIndex(String workoutSessionId) async {
    try {
      final workout = await localDataSource.getWorkoutById(workoutSessionId);
      return workout.exercises.length;
    } catch (e) {
      return 0;
    }
  }

  /// Helper to mark a workout as pending sync
  Future<void> _markWorkoutPendingSync(String workoutSessionId) async {
    try {
      final workout = await localDataSource.getWorkoutById(workoutSessionId);
      final updatedWorkout = workout.copyWith(updatedAt: DateTime.now());
      await localDataSource.upsertWorkoutSession(updatedWorkout);
    } catch (e) {
      // Silently fail
    }
  }
}
