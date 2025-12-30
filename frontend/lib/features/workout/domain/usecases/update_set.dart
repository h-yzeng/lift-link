import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case for updating a set in an exercise
class UpdateSet {
  final WorkoutRepository repository;

  UpdateSet(this.repository);

  Future<Either<Failure, WorkoutSet>> call({
    required String setId,
    int? reps,
    double? weightKg,
    bool? isWarmup,
    double? rpe,
  }) {
    // Validation
    if (setId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Set ID is required')),
      );
    }

    if (reps != null && reps < 0) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Reps cannot be negative'),
        ),
      );
    }

    if (weightKg != null && weightKg < 0) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Weight cannot be negative'),
        ),
      );
    }

    if (rpe != null && (rpe < 0 || rpe > 10)) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'RPE must be between 0 and 10'),
        ),
      );
    }

    return repository.updateSet(
      setId: setId,
      reps: reps,
      weightKg: weightKg,
      isWarmup: isWarmup,
      rpe: rpe,
    );
  }
}
