import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/features/workout/data/models/exercise_performance_model.dart';
import 'package:liftlink/features/workout/data/models/workout_session_model.dart';
import 'package:liftlink/features/workout/data/models/workout_set_model.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';

/// Remote data source for workout sessions using Supabase
abstract class WorkoutRemoteDataSource {
  /// Fetch all workouts for a user
  Future<List<WorkoutSession>> fetchWorkouts({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Fetch a specific workout by ID
  Future<WorkoutSession> fetchWorkoutById(String id);

  /// Create or update a workout session
  Future<WorkoutSession> upsertWorkoutSession(WorkoutSession session);

  /// Create or update an exercise performance
  Future<ExercisePerformance> upsertExercisePerformance(
      ExercisePerformance performance,);

  /// Create or update a set
  Future<WorkoutSet> upsertSet(WorkoutSet set);

  /// Delete a workout session
  Future<void> deleteWorkoutSession(String id);

  /// Sync a complete workout (session + exercises + sets)
  Future<void> syncCompleteWorkout(WorkoutSession session);
}

class WorkoutRemoteDataSourceImpl implements WorkoutRemoteDataSource {
  final SupabaseClient supabaseClient;

  WorkoutRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<WorkoutSession>> fetchWorkouts({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var filterQuery = supabaseClient
          .from('workout_sessions')
          .select('*')
          .eq('user_id', userId);

      if (startDate != null) {
        filterQuery = filterQuery.filter(
          'started_at',
          'gte',
          startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        filterQuery = filterQuery.filter(
          'started_at',
          'lte',
          endDate.toIso8601String(),
        );
      }

      var query = filterQuery.order('started_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      final workoutJsonList = response as List;

      // Load nested data for each workout
      final workouts = <WorkoutSession>[];
      for (final workoutJson in workoutJsonList) {
        final exercises = await _fetchExercisesForWorkout(
          workoutJson['id'] as String,
        );
        workouts.add(
          workoutSessionFromJson(
            workoutJson as Map<String, dynamic>,
            exercises: exercises,
          ),
        );
      }

      return workouts;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Failed to fetch workouts: ${e.toString()}');
    }
  }

  @override
  Future<WorkoutSession> fetchWorkoutById(String id) async {
    try {
      final response = await supabaseClient
          .from('workout_sessions')
          .select('*')
          .eq('id', id)
          .single();

      final exercises = await _fetchExercisesForWorkout(id);

      return workoutSessionFromJson(
        response,
        exercises: exercises,
      );
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Failed to fetch workout: ${e.toString()}');
    }
  }

  @override
  Future<WorkoutSession> upsertWorkoutSession(WorkoutSession session) async {
    try {
      final json = workoutSessionToJson(session);

      await supabaseClient
          .from('workout_sessions')
          .upsert(json, onConflict: 'id');

      return session;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(
        message: 'Failed to upsert workout session: ${e.toString()}',
      );
    }
  }

  @override
  Future<ExercisePerformance> upsertExercisePerformance(
    ExercisePerformance performance,
  ) async {
    try {
      final json = exercisePerformanceToJson(performance);

      await supabaseClient
          .from('exercise_performances')
          .upsert(json, onConflict: 'id');

      return performance;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(
        message: 'Failed to upsert exercise performance: ${e.toString()}',
      );
    }
  }

  @override
  Future<WorkoutSet> upsertSet(WorkoutSet set) async {
    try {
      final json = workoutSetToJson(set);

      await supabaseClient.from('sets').upsert(json, onConflict: 'id');

      return set;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Failed to upsert set: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteWorkoutSession(String id) async {
    try {
      // Supabase cascading deletes will handle exercise_performances and sets
      await supabaseClient.from('workout_sessions').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(
        message: 'Failed to delete workout: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> syncCompleteWorkout(WorkoutSession session) async {
    try {
      // Upsert workout session
      await upsertWorkoutSession(session);

      // Upsert all exercises
      for (final exercise in session.exercises) {
        await upsertExercisePerformance(exercise);

        // Upsert all sets for this exercise
        for (final set in exercise.sets) {
          await upsertSet(set);
        }
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to sync complete workout: ${e.toString()}',
      );
    }
  }

  /// Helper to fetch exercises and sets for a workout
  Future<List<ExercisePerformance>> _fetchExercisesForWorkout(
    String workoutSessionId,
  ) async {
    try {
      final response = await supabaseClient
          .from('exercise_performances')
          .select('*')
          .eq('workout_session_id', workoutSessionId)
          .order('order_index', ascending: true);

      final exerciseJsonList = response as List<dynamic>;

      // Load sets for each exercise
      final exercises = <ExercisePerformance>[];
      for (final exerciseJson in exerciseJsonList) {
        final sets = await _fetchSetsForExercise(
          exerciseJson['id'] as String,
        );
        exercises.add(
          exercisePerformanceFromJson(
            exerciseJson as Map<String, dynamic>,
            sets: sets,
          ),
        );
      }

      return exercises;
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch exercises: ${e.toString()}',
      );
    }
  }

  /// Helper to fetch sets for an exercise
  Future<List<WorkoutSet>> _fetchSetsForExercise(
    String exercisePerformanceId,
  ) async {
    try {
      final response = await supabaseClient
          .from('sets')
          .select('*')
          .eq('exercise_performance_id', exercisePerformanceId)
          .order('set_number', ascending: true);

      final setJsonList = response as List<dynamic>;

      return setJsonList
          .map((json) => workoutSetFromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to fetch sets: ${e.toString()}');
    }
  }
}
