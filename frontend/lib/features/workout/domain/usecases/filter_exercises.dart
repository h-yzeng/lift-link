import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/domain/repositories/exercise_repository.dart';

/// Use case for filtering exercises by multiple criteria
class FilterExercises {
  final ExerciseRepository repository;

  FilterExercises(this.repository);

  Future<Either<Failure, List<Exercise>>> call({
    String? muscleGroup,
    String? equipmentType,
    bool? customOnly,
    String? userId,
  }) {
    return repository.filterExercises(
      muscleGroup: muscleGroup,
      equipmentType: equipmentType,
      customOnly: customOnly,
      userId: userId,
    );
  }
}
