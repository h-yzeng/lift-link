import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/personal_record.dart';
import 'package:liftlink/features/workout/domain/usecases/get_personal_records.dart';

/// Use case for getting the personal record for a specific exercise.
class GetExercisePR {
  final GetPersonalRecords getPersonalRecords;

  GetExercisePR(this.getPersonalRecords);

  /// Gets the personal record for a specific exercise.
  ///
  /// Returns null if no PR exists for this exercise.
  Future<Either<Failure, PersonalRecord?>> call({
    required String userId,
    required String exerciseId,
  }) async {
    final result = await getPersonalRecords(userId: userId);

    return result.fold(
      (failure) => Left(failure),
      (records) {
        final pr = records.where((r) => r.exerciseId == exerciseId).firstOrNull;
        return Right(pr);
      },
    );
  }
}
