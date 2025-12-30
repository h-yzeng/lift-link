import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case for starting a new workout session
class StartWorkout {
  final WorkoutRepository repository;

  StartWorkout(this.repository);

  Future<Either<Failure, WorkoutSession>> call({
    required String userId,
    required String title,
    String? notes,
  }) {
    // Validate inputs
    if (userId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'User ID is required')),
      );
    }

    if (title.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Workout title is required')),
      );
    }

    return repository.startWorkout(
      userId: userId,
      title: title,
      notes: notes,
    );
  }
}
