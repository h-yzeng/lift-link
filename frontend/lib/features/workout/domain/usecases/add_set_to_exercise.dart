import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case for adding a set to an exercise in a workout
class AddSetToExercise {
  final WorkoutRepository repository;

  AddSetToExercise(this.repository);

  Future<Either<Failure, WorkoutSet>> call({
    required String exercisePerformanceId,
    required int setNumber,
    required int reps,
    required double weightKg,
    bool isWarmup = false,
    bool isDropset = false,
    double? rpe,
    String? notes,
  }) {
    // Validate inputs
    if (exercisePerformanceId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Exercise performance ID is required')),
      );
    }

    if (setNumber < 1) {
      return Future.value(
        const Left(ValidationFailure(message: 'Set number must be at least 1')),
      );
    }

    if (reps < 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Reps cannot be negative')),
      );
    }

    if (weightKg < 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Weight cannot be negative')),
      );
    }

    if (rpe != null && (rpe < 0 || rpe > 10)) {
      return Future.value(
        const Left(ValidationFailure(message: 'RPE must be between 0 and 10')),
      );
    }

    return repository.addSetToExercise(
      exercisePerformanceId: exercisePerformanceId,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      isWarmup: isWarmup,
      isDropset: isDropset,
      rpe: rpe,
      notes: notes,
    );
  }
}
