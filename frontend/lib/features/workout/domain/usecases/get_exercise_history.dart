import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_history.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case for retrieving exercise history.
///
/// Returns the last N workout sessions where the user performed
/// a specific exercise, with all sets included. This is useful for
/// showing users their previous performance when adding sets.
class GetExerciseHistory {
  final WorkoutRepository repository;

  const GetExerciseHistory(this.repository);

  /// Get exercise history for a specific exercise.
  ///
  /// Parameters:
  /// - [userId]: The ID of the user
  /// - [exerciseId]: The ID of the exercise to get history for
  /// - [limit]: Maximum number of previous sessions to return (default: 3)
  ///
  /// Returns:
  /// - Right([ExerciseHistory]): The exercise history with sessions
  /// - Left([Failure]): If an error occurred
  Future<Either<Failure, ExerciseHistory>> call({
    required String userId,
    required String exerciseId,
    int limit = 3,
  }) async {
    return await repository.getExerciseHistory(
      userId: userId,
      exerciseId: exerciseId,
      limit: limit,
    );
  }
}
