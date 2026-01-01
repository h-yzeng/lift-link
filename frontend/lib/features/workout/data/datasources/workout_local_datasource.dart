import 'package:drift/drift.dart';
import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/features/workout/data/models/exercise_performance_model.dart';
import 'package:liftlink/features/workout/data/models/workout_session_model.dart';
import 'package:liftlink/features/workout/data/models/workout_set_model.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_history.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/shared/database/app_database.dart';

/// Local data source for workout sessions using Drift
abstract class WorkoutLocalDataSource {
  /// Start a new workout session
  Future<WorkoutSession> startWorkout(WorkoutSession session);

  /// Get the current active (in-progress) workout for a user
  Future<WorkoutSession?> getActiveWorkout(String userId);

  /// Add an exercise to a workout session
  Future<ExercisePerformance> addExerciseToWorkout(
      ExercisePerformance performance,);

  /// Add a set to an exercise
  Future<WorkoutSet> addSetToExercise(WorkoutSet set);

  /// Get a set by ID
  Future<WorkoutSet?> getSetById(String setId);

  /// Update a set
  Future<WorkoutSet> updateSet(WorkoutSet set);

  /// Remove a set
  Future<void> removeSet(String setId);

  /// Remove an exercise and all its sets
  Future<void> removeExercise(String exercisePerformanceId);

  /// Complete a workout session
  Future<WorkoutSession> completeWorkout(String workoutSessionId);

  /// Get a workout by ID with all nested data
  Future<WorkoutSession> getWorkoutById(String id);

  /// Get workout history for a user
  Future<List<WorkoutSession>> getWorkoutHistory({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Upsert workout session
  Future<void> upsertWorkoutSession(WorkoutSession session);

  /// Upsert exercise performance
  Future<void> upsertExercisePerformance(ExercisePerformance performance);

  /// Upsert set
  Future<void> upsertSet(WorkoutSet set);

  /// Get all pending sync workout sessions
  Future<List<WorkoutSession>> getPendingSyncWorkouts(String userId);

  /// Mark workout as synced
  Future<void> markWorkoutAsSynced(String workoutSessionId);

  /// Get exercise history for a specific exercise
  /// Returns the last N completed workout sessions with all sets
  Future<ExerciseHistory> getExerciseHistory({
    required String userId,
    required String exerciseId,
    int limit = 3,
  });
}

class WorkoutLocalDataSourceImpl implements WorkoutLocalDataSource {
  final AppDatabase database;

  WorkoutLocalDataSourceImpl({required this.database});

  @override
  Future<WorkoutSession> startWorkout(WorkoutSession session) async {
    try {
      await database.into(database.workoutSessions).insert(
            session.toCompanion(isPendingSync: true),
          );
      return session;
    } catch (e) {
      throw CacheException(message: 'Failed to start workout: ${e.toString()}');
    }
  }

  @override
  Future<WorkoutSession?> getActiveWorkout(String userId) async {
    try {
      // Find the active workout (completedAt is null)
      final query = database.select(database.workoutSessions)
        ..where((ws) => ws.userId.equals(userId) & ws.completedAt.isNull())
        ..orderBy([(ws) => OrderingTerm.desc(ws.startedAt)])
        ..limit(1);

      final workoutEntity = await query.getSingleOrNull();
      if (workoutEntity == null) return null;

      // Load exercises and sets for this workout
      final exercises =
          await _loadExercisesForWorkout(workoutEntity.id);

      return workoutEntity.toEntity(exercises: exercises);
    } catch (e) {
      throw CacheException(
        message: 'Failed to get active workout: ${e.toString()}',
      );
    }
  }

  @override
  Future<ExercisePerformance> addExerciseToWorkout(
    ExercisePerformance performance,
  ) async {
    try {
      final companion = performance.toCompanion();
      await database.into(database.exercisePerformances).insert(companion);

      // Mark workout as pending sync
      await _markWorkoutPendingSync(performance.id);

      return performance;
    } catch (e) {
      // Enhanced error message for debugging
      throw CacheException(
        message: 'Failed to add exercise to workout: ${e.toString()}\n'
            'Performance ID: ${performance.id}\n'
            'Workout ID: ${performance.workoutSessionId}\n'
            'Exercise: ${performance.exerciseName}',
      );
    }
  }

  @override
  Future<WorkoutSet> addSetToExercise(WorkoutSet set) async {
    try {
      await database.into(database.sets).insert(set.toCompanion());

      // Mark workout as pending sync
      await _markWorkoutPendingSync(set.exercisePerformanceId);

      return set;
    } catch (e) {
      throw CacheException(message: 'Failed to add set: ${e.toString()}');
    }
  }

  @override
  Future<WorkoutSet?> getSetById(String setId) async {
    try {
      final query = database.select(database.sets)
        ..where((s) => s.id.equals(setId));

      final result = await query.getSingleOrNull();
      return result?.toEntity();
    } catch (e) {
      throw CacheException(message: 'Failed to get set: ${e.toString()}');
    }
  }

  @override
  Future<WorkoutSet> updateSet(WorkoutSet set) async {
    try {
      await database.update(database.sets).replace(set.toCompanion());

      // Mark workout as pending sync
      await _markWorkoutPendingSync(set.exercisePerformanceId);

      return set;
    } catch (e) {
      throw CacheException(message: 'Failed to update set: ${e.toString()}');
    }
  }

  @override
  Future<void> removeSet(String setId) async {
    try {
      // Get the exercise performance ID before deleting
      final setQuery = database.select(database.sets)
        ..where((s) => s.id.equals(setId));
      final setEntity = await setQuery.getSingleOrNull();

      if (setEntity != null) {
        await (database.delete(database.sets)..where((s) => s.id.equals(setId)))
            .go();

        // Mark workout as pending sync
        await _markWorkoutPendingSync(setEntity.exercisePerformanceId);
      }
    } catch (e) {
      throw CacheException(message: 'Failed to remove set: ${e.toString()}');
    }
  }

  @override
  Future<void> removeExercise(String exercisePerformanceId) async {
    try {
      // Delete all sets for this exercise
      await (database.delete(database.sets)
            ..where((s) => s.exercisePerformanceId.equals(exercisePerformanceId)))
          .go();

      // Delete the exercise performance
      await (database.delete(database.exercisePerformances)
            ..where((ep) => ep.id.equals(exercisePerformanceId)))
          .go();

      // Mark workout as pending sync
      await _markWorkoutPendingSync(exercisePerformanceId);
    } catch (e) {
      throw CacheException(message: 'Failed to remove exercise: ${e.toString()}');
    }
  }

  @override
  Future<WorkoutSession> completeWorkout(String workoutSessionId) async {
    try {
      final now = DateTime.now();

      // Get the workout to calculate duration
      final workoutQuery = database.select(database.workoutSessions)
        ..where((ws) => ws.id.equals(workoutSessionId));
      final workout = await workoutQuery.getSingle();

      final durationMinutes = now.difference(workout.startedAt).inMinutes;

      // Update the workout
      await (database.update(database.workoutSessions)
            ..where((ws) => ws.id.equals(workoutSessionId)))
          .write(
        WorkoutSessionsCompanion(
          completedAt: Value(now),
          durationMinutes: Value(durationMinutes),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );

      // Return the updated workout
      return getWorkoutById(workoutSessionId);
    } catch (e) {
      throw CacheException(
        message: 'Failed to complete workout: ${e.toString()}',
      );
    }
  }

  @override
  Future<WorkoutSession> getWorkoutById(String id) async {
    try {
      final query = database.select(database.workoutSessions)
        ..where((ws) => ws.id.equals(id));

      final workoutEntity = await query.getSingleOrNull();
      if (workoutEntity == null) {
        throw const CacheException(message: 'Workout not found');
      }

      final exercises = await _loadExercisesForWorkout(id);
      return workoutEntity.toEntity(exercises: exercises);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: 'Failed to get workout: ${e.toString()}');
    }
  }

  @override
  Future<List<WorkoutSession>> getWorkoutHistory({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final query = database.select(database.workoutSessions)
        ..where((ws) => ws.userId.equals(userId) & ws.completedAt.isNotNull());

      if (startDate != null) {
        query.where((ws) => ws.startedAt.isBiggerOrEqualValue(startDate));
      }

      if (endDate != null) {
        query.where((ws) => ws.startedAt.isSmallerOrEqualValue(endDate));
      }

      query.orderBy([(ws) => OrderingTerm.desc(ws.startedAt)]);

      if (limit != null) {
        query.limit(limit);
      }

      final workoutEntities = await query.get();

      // Load exercises for each workout
      final workouts = <WorkoutSession>[];
      for (final entity in workoutEntities) {
        final exercises = await _loadExercisesForWorkout(entity.id);
        workouts.add(entity.toEntity(exercises: exercises));
      }

      return workouts;
    } catch (e) {
      throw CacheException(
        message: 'Failed to get workout history: ${e.toString()}',
      );
    }
  }

  @override
  Future<ExerciseHistory> getExerciseHistory({
    required String userId,
    required String exerciseId,
    int limit = 3,
  }) async {
    try {
      // Query to get the last N completed workouts that included this exercise
      final workoutQuery = database.select(database.workoutSessions).join([
        innerJoin(
          database.exercisePerformances,
          database.exercisePerformances.workoutSessionId.equalsExp(database.workoutSessions.id),
        ),
      ])
        ..where(
          database.workoutSessions.userId.equals(userId) &
              database.workoutSessions.completedAt.isNotNull() &
              database.exercisePerformances.exerciseId.equals(exerciseId),
        )
        ..orderBy([OrderingTerm.desc(database.workoutSessions.completedAt)])
        ..limit(limit);

      final workoutResults = await workoutQuery.get();

      // Group by workout session and build history sessions
      final sessions = <ExerciseHistorySession>[];
      final seenWorkouts = <String>{};

      for (final row in workoutResults) {
        final workoutEntity = row.readTable(database.workoutSessions);

        // Skip if we've already processed this workout
        if (seenWorkouts.contains(workoutEntity.id)) continue;
        seenWorkouts.add(workoutEntity.id);

        // Get all sets for this exercise in this workout
        final exercisePerfQuery = database.select(database.exercisePerformances)
          ..where((ep) =>
            ep.workoutSessionId.equals(workoutEntity.id) &
            ep.exerciseId.equals(exerciseId),
          );

        final exercisePerfs = await exercisePerfQuery.get();
        if (exercisePerfs.isEmpty) continue;

        final exercisePerfId = exercisePerfs.first.id;

        // Get all sets for this exercise performance
        final setsQuery = database.select(database.sets)
          ..where((s) => s.exercisePerformanceId.equals(exercisePerfId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]);

        final setEntities = await setsQuery.get();

        // Convert to HistoricalSet entities
        final historicalSets = setEntities.map((setEntity) {
          return HistoricalSet(
            setNumber: setEntity.setNumber,
            reps: setEntity.reps,
            weightKg: setEntity.weightKg,
            isWarmup: setEntity.isWarmup,
            rpe: setEntity.rpe,
          );
        }).toList();

        // Create history session
        sessions.add(
          ExerciseHistorySession(
            workoutSessionId: workoutEntity.id,
            workoutTitle: workoutEntity.title,
            completedAt: workoutEntity.completedAt!,
            sets: historicalSets,
          ),
        );
      }

      return ExerciseHistory(
        exerciseId: exerciseId,
        userId: userId,
        sessions: sessions,
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to get exercise history: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> upsertWorkoutSession(WorkoutSession session) async {
    try {
      await database
          .into(database.workoutSessions)
          .insertOnConflictUpdate(session.toCompanion());
    } catch (e) {
      throw CacheException(
        message: 'Failed to upsert workout session: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> upsertExercisePerformance(ExercisePerformance performance) async {
    try {
      await database
          .into(database.exercisePerformances)
          .insertOnConflictUpdate(performance.toCompanion());
    } catch (e) {
      throw CacheException(
        message: 'Failed to upsert exercise performance: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> upsertSet(WorkoutSet set) async {
    try {
      await database.into(database.sets).insertOnConflictUpdate(set.toCompanion());
    } catch (e) {
      throw CacheException(message: 'Failed to upsert set: ${e.toString()}');
    }
  }

  @override
  Future<List<WorkoutSession>> getPendingSyncWorkouts(String userId) async {
    try {
      final query = database.select(database.workoutSessions)
        ..where((ws) => ws.userId.equals(userId) & ws.isPendingSync.equals(true))
        ..orderBy([(ws) => OrderingTerm.asc(ws.updatedAt)]);

      final workoutEntities = await query.get();

      final workouts = <WorkoutSession>[];
      for (final entity in workoutEntities) {
        final exercises = await _loadExercisesForWorkout(entity.id);
        workouts.add(entity.toEntity(exercises: exercises));
      }

      return workouts;
    } catch (e) {
      throw CacheException(
        message: 'Failed to get pending sync workouts: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> markWorkoutAsSynced(String workoutSessionId) async {
    try {
      await (database.update(database.workoutSessions)
            ..where((ws) => ws.id.equals(workoutSessionId)))
          .write(
        WorkoutSessionsCompanion(
          isPendingSync: const Value(false),
          syncedAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to mark workout as synced: ${e.toString()}',
      );
    }
  }

  /// Helper to load all exercises and sets for a workout
  Future<List<ExercisePerformance>> _loadExercisesForWorkout(
    String workoutSessionId,
  ) async {
    // Get all exercise performances for this workout
    final exerciseQuery = database.select(database.exercisePerformances)
      ..where((ep) => ep.workoutSessionId.equals(workoutSessionId))
      ..orderBy([(ep) => OrderingTerm.asc(ep.orderIndex)]);

    final exerciseEntities = await exerciseQuery.get();

    // Load sets for each exercise
    final exercises = <ExercisePerformance>[];
    for (final exerciseEntity in exerciseEntities) {
      final sets = await _loadSetsForExercise(exerciseEntity.id);
      exercises.add(exerciseEntity.toEntity(sets: sets));
    }

    return exercises;
  }

  /// Helper to load all sets for an exercise
  Future<List<WorkoutSet>> _loadSetsForExercise(
    String exercisePerformanceId,
  ) async {
    final setQuery = database.select(database.sets)
      ..where((s) => s.exercisePerformanceId.equals(exercisePerformanceId))
      ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]);

    final setEntities = await setQuery.get();
    return setEntities.map((e) => e.toEntity()).toList();
  }

  /// Helper to mark a workout as pending sync given an exercise performance ID
  Future<void> _markWorkoutPendingSync(String exercisePerformanceId) async {
    try {
      // Get the exercise performance to find the workout ID
      final epQuery = database.select(database.exercisePerformances)
        ..where((ep) => ep.id.equals(exercisePerformanceId));
      final ep = await epQuery.getSingleOrNull();

      if (ep != null) {
        await (database.update(database.workoutSessions)
              ..where((ws) => ws.id.equals(ep.workoutSessionId)))
            .write(
          const WorkoutSessionsCompanion(
            isPendingSync: Value(true),
          ),
        );
      }
    } catch (e) {
      // Silently fail - marking as pending sync is not critical
    }
  }
}
