import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';
import 'package:liftlink/features/workout/domain/repositories/exercise_repository.dart';

/// Use case for adding an exercise to a workout session
class AddExerciseToWorkout {
  final WorkoutRepository workoutRepository;
  final ExerciseRepository exerciseRepository;

  AddExerciseToWorkout({
    required this.workoutRepository,
    required this.exerciseRepository,
  });

  Future<Either<Failure, ExercisePerformance>> call({
    required String workoutSessionId,
    required String exerciseId,
    required String exerciseName,
    int? orderIndex,
    String? notes,
  }) async {
    // Validate inputs
    if (workoutSessionId.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Workout session ID is required'),
      );
    }

    if (exerciseId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Exercise ID is required'));
    }

    if (exerciseName.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Exercise name is required'),
      );
    }

    // Add exercise to workout
    final result = await workoutRepository.addExerciseToWorkout(
      workoutSessionId: workoutSessionId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      orderIndex: orderIndex,
      notes: notes,
    );

    // Update exercise usage tracking (fire and forget)
    if (result.isRight()) {
      exerciseRepository.updateExerciseUsage(exerciseId);
    }

    return result;
  }
}
