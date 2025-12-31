import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/workout/data/datasources/template_local_data_source.dart';
import 'package:liftlink/features/workout/data/repositories/template_repository_impl.dart';
import 'package:liftlink/features/workout/domain/entities/workout_template.dart';
import 'package:liftlink/features/workout/domain/repositories/template_repository.dart';
import 'package:liftlink/features/workout/domain/usecases/create_template.dart';
import 'package:liftlink/features/workout/domain/usecases/delete_template.dart';
import 'package:liftlink/features/workout/domain/usecases/get_templates.dart';
import 'package:liftlink/shared/database/app_database.dart' as db;

/// Provider for template local data source.
final templateLocalDataSourceProvider = Provider<TemplateLocalDataSource>((ref) {
  final database = ref.watch(profileDatabaseProvider);
  return TemplateLocalDataSource(database);
});

/// Provider for template repository.
final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  final localDataSource = ref.watch(templateLocalDataSourceProvider);
  return TemplateRepositoryImpl(localDataSource);
});

/// Provider for GetTemplates use case.
final getTemplatesUseCaseProvider = Provider<GetTemplates>((ref) {
  final repository = ref.watch(templateRepositoryProvider);
  return GetTemplates(repository);
});

/// Provider for CreateTemplate use case.
final createTemplateUseCaseProvider = Provider<CreateTemplate>((ref) {
  final repository = ref.watch(templateRepositoryProvider);
  return CreateTemplate(repository);
});

/// Provider for DeleteTemplate use case.
final deleteTemplateUseCaseProvider = Provider<DeleteTemplate>((ref) {
  final repository = ref.watch(templateRepositoryProvider);
  return DeleteTemplate(repository);
});

/// Provider that fetches all templates for the current user.
final templatesProvider = FutureProvider<List<WorkoutTemplate>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    return [];
  }

  final useCase = ref.watch(getTemplatesUseCaseProvider);
  final result = await useCase(userId: user.id);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (templates) => templates,
  );
});
