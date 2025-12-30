import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:liftlink/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:liftlink/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/profile/domain/repositories/profile_repository.dart';
import 'package:liftlink/features/profile/domain/usecases/get_profile.dart';
import 'package:liftlink/features/profile/domain/usecases/update_profile.dart';
import 'package:liftlink/shared/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

part 'profile_providers.g.dart';

// Infrastructure providers
@riverpod
NetworkInfo profileNetworkInfo(Ref ref) {
  return NetworkInfoImpl(connectivity: Connectivity());
}

@riverpod
AppDatabase profileDatabase(Ref ref) {
  return AppDatabase();
}

// Data source providers
@riverpod
ProfileLocalDataSource profileLocalDataSource(Ref ref) {
  return ProfileLocalDataSourceImpl(
    database: ref.watch(profileDatabaseProvider),
  );
}

@riverpod
ProfileRemoteDataSource profileRemoteDataSource(Ref ref) {
  return ProfileRemoteDataSourceImpl(
    supabaseClient: supabase.Supabase.instance.client,
  );
}

// Repository provider
@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(
    localDataSource: ref.watch(profileLocalDataSourceProvider),
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    networkInfo: ref.watch(profileNetworkInfoProvider),
  );
}

// Use case providers
@riverpod
GetProfile getProfile(Ref ref) {
  return GetProfile(ref.watch(profileRepositoryProvider));
}

@riverpod
UpdateProfile updateProfile(Ref ref) {
  return UpdateProfile(ref.watch(profileRepositoryProvider));
}

// Profile state provider
@riverpod
Future<Profile?> currentProfile(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    return null;
  }

  final useCase = ref.watch(getProfileProvider);
  final result = await useCase(user.id);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (profile) => profile,
  );
}

// Watch profile stream
@riverpod
Stream<Profile?> watchCurrentProfile(Ref ref) async* {
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) {
    yield null;
    return;
  }

  final repository = ref.watch(profileRepositoryProvider);
  yield* repository.watchProfile(user.id);
}
