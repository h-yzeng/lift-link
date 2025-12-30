import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case for getting the current active workout session
class GetActiveWorkout {
  final WorkoutRepository repository;

  GetActiveWorkout(this.repository);

  Future<Either<Failure, WorkoutSession?>> call({
    required String userId,
  }) {
    if (userId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'User ID is required')),
      );
    }

    return repository.getActiveWorkout(userId: userId);
  }
}
