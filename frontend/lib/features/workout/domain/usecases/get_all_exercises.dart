import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/domain/repositories/exercise_repository.dart';

/// Use case for getting all exercises
class GetAllExercises {
  final ExerciseRepository repository;

  GetAllExercises(this.repository);

  Future<Either<Failure, List<Exercise>>> call({String? userId}) {
    return repository.getAllExercises(userId: userId);
  }
}
