import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/data/datasources/template_local_data_source.dart';
import 'package:liftlink/features/workout/domain/entities/workout_template.dart';
import 'package:liftlink/features/workout/domain/repositories/template_repository.dart';

/// Implementation of TemplateRepository.
class TemplateRepositoryImpl implements TemplateRepository {
  final TemplateLocalDataSource _localDataSource;

  TemplateRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, List<WorkoutTemplate>>> getTemplates(String userId) async {
    try {
      final templates = await _localDataSource.getTemplates(userId);
      return Right(templates);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to load templates: $e',
      ),);
    }
  }

  @override
  Future<Either<Failure, WorkoutTemplate?>> getTemplateById(String id) async {
    try {
      final template = await _localDataSource.getTemplateById(id);
      return Right(template);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to load template: $e',
      ),);
    }
  }

  @override
  Future<Either<Failure, WorkoutTemplate>> createTemplate(WorkoutTemplate template) async {
    try {
      await _localDataSource.insertTemplate(template);
      return Right(template);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to create template: $e',
      ),);
    }
  }

  @override
  Future<Either<Failure, WorkoutTemplate>> updateTemplate(WorkoutTemplate template) async {
    try {
      await _localDataSource.updateTemplate(template);
      return Right(template);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to update template: $e',
      ),);
    }
  }

  @override
  Future<Either<Failure, void>> deleteTemplate(String id) async {
    try {
      await _localDataSource.deleteTemplate(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to delete template: $e',
      ),);
    }
  }
}
