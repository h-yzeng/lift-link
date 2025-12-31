import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_template.dart';

/// Repository interface for workout templates.
abstract class TemplateRepository {
  /// Get all templates for a user.
  Future<Either<Failure, List<WorkoutTemplate>>> getTemplates(String userId);

  /// Get a single template by ID.
  Future<Either<Failure, WorkoutTemplate?>> getTemplateById(String id);

  /// Create a new template.
  Future<Either<Failure, WorkoutTemplate>> createTemplate(WorkoutTemplate template);

  /// Update an existing template.
  Future<Either<Failure, WorkoutTemplate>> updateTemplate(WorkoutTemplate template);

  /// Delete a template.
  Future<Either<Failure, void>> deleteTemplate(String id);
}
