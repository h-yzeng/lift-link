import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/repositories/template_repository.dart';

/// Use case to delete a workout template.
class DeleteTemplate {
  final TemplateRepository _repository;

  DeleteTemplate(this._repository);

  Future<Either<Failure, void>> call({
    required String templateId,
  }) {
    return _repository.deleteTemplate(templateId);
  }
}
