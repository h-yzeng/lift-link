import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_template.dart';
import 'package:liftlink/features/workout/domain/repositories/template_repository.dart';

/// Use case to get all templates for a user.
class GetTemplates {
  final TemplateRepository _repository;

  GetTemplates(this._repository);

  Future<Either<Failure, List<WorkoutTemplate>>> call({
    required String userId,
  }) {
    return _repository.getTemplates(userId);
  }
}
