import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_template.dart';
import 'package:liftlink/features/workout/domain/repositories/template_repository.dart';
import 'package:uuid/uuid.dart';

/// Use case to create a new workout template.
class CreateTemplate {
  final TemplateRepository _repository;

  CreateTemplate(this._repository);

  Future<Either<Failure, WorkoutTemplate>> call({
    required String userId,
    required String name,
    String? description,
    required List<TemplateExercise> exercises,
  }) {
    final now = DateTime.now();
    final template = WorkoutTemplate(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      description: description,
      exercises: exercises,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.createTemplate(template);
  }
}
