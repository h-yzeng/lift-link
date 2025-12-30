import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/domain/repositories/exercise_repository.dart';

/// Use case for searching exercises by name
class SearchExercises {
  final ExerciseRepository repository;

  SearchExercises(this.repository);

  Future<Either<Failure, List<Exercise>>> call({
    required String query,
    String? userId,
  }) {
    // Validate query
    if (query.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure(message: 'Search query cannot be empty')),
      );
    }

    return repository.searchExercises(query: query.trim(), userId: userId);
  }
}
