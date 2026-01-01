import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_history.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';

/// Repository interface for workout operations
abstract class WorkoutRepository {
  /// Start a new workout session
  Future<Either<Failure, WorkoutSession>> startWorkout({
    required String userId,
    required String title,
    String? notes,
  });

  /// Get the current active (in-progress) workout for a user
  Future<Either<Failure, WorkoutSession?>> getActiveWorkout({
    required String userId,
  });

  /// Add an exercise to the current workout session
  Future<Either<Failure, ExercisePerformance>> addExerciseToWorkout({
    required String workoutSessionId,
    required String exerciseId,
    required String exerciseName,
    int? orderIndex,
    String? notes,
  });

  /// Add a set to an exercise in the workout
  Future<Either<Failure, WorkoutSet>> addSetToExercise({
    required String exercisePerformanceId,
    required int setNumber,
    required int reps,
    required double weightKg,
    bool isWarmup = false,
    bool isDropset = false,
    double? rpe,
    String? notes,
  });

  /// Update an existing set
  Future<Either<Failure, WorkoutSet>> updateSet({
    required String setId,
    int? reps,
    double? weightKg,
    bool? isWarmup,
    bool? isDropset,
    double? rpe,
    String? notes,
  });

  /// Remove a set from an exercise
  Future<Either<Failure, void>> removeSet(String setId);

  /// Remove an exercise from the workout
  Future<Either<Failure, void>> removeExercise(String exercisePerformanceId);

  /// Complete the current workout session
  Future<Either<Failure, WorkoutSession>> completeWorkout({
    required String workoutSessionId,
    String? notes,
  });

  /// Get a specific workout session by ID
  Future<Either<Failure, WorkoutSession>> getWorkoutById(String id);

  /// Get workout history for a user
  Future<Either<Failure, List<WorkoutSession>>> getWorkoutHistory({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get exercise history for a specific exercise
  /// Returns the last N sessions (default 3) with all sets
  Future<Either<Failure, ExerciseHistory>> getExerciseHistory({
    required String userId,
    required String exerciseId,
    int limit = 3,
  });

  /// Sync workouts with remote server
  Future<Either<Failure, void>> syncWorkouts({String? userId});
}
