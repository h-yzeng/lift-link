import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/personal_record.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case for getting all personal records for a user.
///
/// Analyzes all historical workouts to find the best 1RM for each exercise.
class GetPersonalRecords {
  final WorkoutRepository repository;

  GetPersonalRecords(this.repository);

  /// Gets all personal records for the user.
  ///
  /// Returns a list of [PersonalRecord]s sorted by 1RM descending.
  Future<Either<Failure, List<PersonalRecord>>> call({
    required String userId,
  }) async {
    // Get all completed workouts for the user
    final workoutsResult = await repository.getWorkoutHistory(
      userId: userId,
      limit: 1000, // Get all workouts
    );

    return workoutsResult.fold(
      (failure) => Left(failure),
      (workouts) {
        // Map to track best 1RM for each exercise
        final Map<String, PersonalRecord> bestRecords = {};

        // Iterate through all workouts
        for (final workout in workouts) {
          // Skip incomplete workouts
          if (!workout.isCompleted) continue;

          // Check each exercise in the workout
          for (final exercise in workout.exercises) {
            // Get the best set for this exercise
            final bestSet = exercise.sets
                .where((set) => !set.isWarmup && set.calculated1RM != null)
                .fold<({double oneRM, double weight, int reps})?>(
              null,
              (best, set) {
                final oneRM = set.calculated1RM!;
                if (best == null || oneRM > best.oneRM) {
                  return (oneRM: oneRM, weight: set.weightKg, reps: set.reps);
                }
                return best;
              },
            );

            if (bestSet == null) continue;

            final exerciseId = exercise.exerciseId;
            final exerciseName = exercise.exerciseName;

            // Check if this is a new PR for this exercise
            final existingPR = bestRecords[exerciseId];
            if (existingPR == null ||
                bestSet.oneRM > existingPR.oneRepMax) {
              bestRecords[exerciseId] = PersonalRecord(
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                userId: userId,
                weight: bestSet.weight,
                reps: bestSet.reps,
                oneRepMax: bestSet.oneRM,
                achievedAt: workout.completedAt!,
                workoutId: workout.id,
              );
            }
          }
        }

        // Convert to list and sort by 1RM descending
        final records = bestRecords.values.toList()
          ..sort((a, b) => b.oneRepMax.compareTo(a.oneRepMax));

        return Right(records);
      },
    );
  }
}
