import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case for retrieving workout history
class GetWorkoutHistory {
  final WorkoutRepository repository;

  GetWorkoutHistory(this.repository);

  Future<Either<Failure, List<WorkoutSession>>> call({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (userId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'User ID is required')),
      );
    }

    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Start date must be before end date'),
        ),
      );
    }

    return repository.getWorkoutHistory(
      userId: userId,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
