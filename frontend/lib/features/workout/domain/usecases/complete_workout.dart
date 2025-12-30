import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case for completing a workout session
class CompleteWorkout {
  final WorkoutRepository repository;

  CompleteWorkout(this.repository);

  Future<Either<Failure, WorkoutSession>> call({
    required String workoutSessionId,
    String? notes,
  }) {
    if (workoutSessionId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Workout session ID is required')),
      );
    }

    return repository.completeWorkout(
      workoutSessionId: workoutSessionId,
      notes: notes,
    );
  }
}
