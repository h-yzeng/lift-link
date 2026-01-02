import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/workout/data/datasources/exercise_local_datasource.dart';
import 'package:liftlink/features/workout/data/datasources/exercise_remote_datasource.dart';
import 'package:liftlink/features/workout/data/repositories/exercise_repository_impl.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/domain/repositories/exercise_repository.dart';
import 'package:liftlink/features/workout/domain/usecases/filter_exercises.dart';
import 'package:liftlink/features/workout/domain/usecases/get_all_exercises.dart';
import 'package:liftlink/features/workout/domain/usecases/search_exercises.dart';
import 'package:liftlink/shared/database/database_provider.dart';

part 'exercise_providers.g.dart';

// Infrastructure providers
@riverpod
NetworkInfo networkInfo(Ref ref) {
  return NetworkInfoImpl(connectivity: Connectivity());
}

// Data source providers
@riverpod
ExerciseLocalDataSource exerciseLocalDataSource(Ref ref) {
  return ExerciseLocalDataSourceImpl(
    database: ref.watch(databaseProvider),
  );
}

@riverpod
ExerciseRemoteDataSource exerciseRemoteDataSource(Ref ref) {
  return ExerciseRemoteDataSourceImpl(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
}

// Repository provider
@riverpod
ExerciseRepository exerciseRepository(Ref ref) {
  return ExerciseRepositoryImpl(
    localDataSource: ref.watch(exerciseLocalDataSourceProvider),
    remoteDataSource: ref.watch(exerciseRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
}

// Use case providers
@riverpod
GetAllExercises getAllExercisesUseCase(Ref ref) {
  return GetAllExercises(ref.watch(exerciseRepositoryProvider));
}

@riverpod
SearchExercises searchExercisesUseCase(Ref ref) {
  return SearchExercises(ref.watch(exerciseRepositoryProvider));
}

@riverpod
FilterExercises filterExercisesUseCase(Ref ref) {
  return FilterExercises(ref.watch(exerciseRepositoryProvider));
}

// Exercise list provider with optional filters
@riverpod
Future<List<Exercise>> exerciseList(
  Ref ref, {
  String? muscleGroup,
  String? equipmentType,
  bool? customOnly,
}) async {
  final user = await ref.watch(currentUserProvider.future);
  final useCase = ref.watch(filterExercisesUseCaseProvider);

  final result = await useCase(
    muscleGroup: muscleGroup,
    equipmentType: equipmentType,
    customOnly: customOnly,
    userId: user?.id,
  );

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (exercises) => exercises,
  );
}

// Search results provider
@riverpod
Future<List<Exercise>> exerciseSearchResults(
  Ref ref,
  String query,
) async {
  if (query.trim().isEmpty) {
    return [];
  }

  final user = await ref.watch(currentUserProvider.future);
  final useCase = ref.watch(searchExercisesUseCaseProvider);

  final result = await useCase(
    query: query,
    userId: user?.id,
  );

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (exercises) => exercises,
  );
}
