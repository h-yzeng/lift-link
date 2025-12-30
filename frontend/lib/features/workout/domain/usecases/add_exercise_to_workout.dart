import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case for adding an exercise to a workout session
class AddExerciseToWorkout {
  final WorkoutRepository repository;

  AddExerciseToWorkout(this.repository);

  Future<Either<Failure, ExercisePerformance>> call({
    required String workoutSessionId,
    required String exerciseId,
    required String exerciseName,
    int? orderIndex,
    String? notes,
  }) {
    // Validate inputs
    if (workoutSessionId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Workout session ID is required')),
      );
    }

    if (exerciseId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Exercise ID is required')),
      );
    }

    if (exerciseName.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Exercise name is required')),
      );
    }

    return repository.addExerciseToWorkout(
      workoutSessionId: workoutSessionId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      orderIndex: orderIndex,
      notes: notes,
    );
  }
}
