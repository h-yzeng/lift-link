import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:liftlink/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:liftlink/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:liftlink/features/auth/domain/entities/user.dart'
    as auth_entity;
import 'package:liftlink/features/auth/domain/repositories/auth_repository.dart';
import 'package:liftlink/features/auth/domain/usecases/get_current_user.dart';
import 'package:liftlink/features/auth/domain/usecases/login_with_email.dart';
import 'package:liftlink/features/auth/domain/usecases/logout.dart';
import 'package:liftlink/features/auth/domain/usecases/register_with_email.dart';
import 'package:liftlink/features/auth/domain/usecases/reset_password.dart';
import 'package:liftlink/features/auth/domain/usecases/update_password.dart';

part 'auth_providers.g.dart';

typedef AuthUser = auth_entity.User;

// Infrastructure providers
@riverpod
supabase.SupabaseClient supabaseClient(Ref ref) {
  return supabase.Supabase.instance.client;
}

@riverpod
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return SharedPreferences.getInstance();
}

@riverpod
NetworkInfo networkInfo(Ref ref) {
  return NetworkInfoImpl(connectivity: Connectivity());
}

// Data source providers
@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  return AuthRemoteDataSourceImpl(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
}

@riverpod
Future<AuthLocalDataSource> authLocalDataSource(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AuthLocalDataSourceImpl(sharedPreferences: prefs);
}

// Repository provider
@riverpod
Future<AuthRepository> authRepository(Ref ref) async {
  final localDataSource = await ref.watch(authLocalDataSourceProvider.future);
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: localDataSource,
    networkInfo: ref.watch(networkInfoProvider),
  );
}

// Use case providers
@riverpod
Future<GetCurrentUser> getCurrentUserUseCase(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return GetCurrentUser(repository);
}

@riverpod
Future<LoginWithEmail> loginWithEmailUseCase(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return LoginWithEmail(repository);
}

@riverpod
Future<RegisterWithEmail> registerWithEmailUseCase(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return RegisterWithEmail(repository);
}

@riverpod
Future<Logout> logoutUseCase(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return Logout(repository);
}

@riverpod
Future<UpdatePassword> updatePasswordUseCase(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return UpdatePassword(repository);
}

@riverpod
Future<ResetPassword> resetPasswordUseCase(Ref ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return ResetPassword(repository);
}

// Auth state provider - Stream of current domain user
@riverpod
Stream<AuthUser?> authStateChanges(Ref ref) {
  return ref.watch(authRemoteDataSourceProvider).authStateChanges;
}

// Current user provider (Domain User)
@riverpod
Future<AuthUser?> currentUser(Ref ref) async {
  final useCase = await ref.watch(getCurrentUserUseCaseProvider.future);
  final result = await useCase();
  return result.fold((failure) => null, (user) => user);
}
