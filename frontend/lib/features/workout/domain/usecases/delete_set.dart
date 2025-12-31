import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case for deleting a set from an exercise
class DeleteSet {
  final WorkoutRepository repository;

  DeleteSet(this.repository);

  Future<Either<Failure, void>> call({
    required String setId,
  }) {
    // Validation
    if (setId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Set ID is required')),
      );
    }

    return repository.removeSet(setId);
  }
}
