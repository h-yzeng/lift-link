import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:liftlink/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource localDataSource;
  final ProfileRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProfileRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Profile>> getProfile(String userId) async {
    try {
      // Try to get from local first
      final profile = await localDataSource.getProfile(userId);

      // Sync in background if online
      if (await networkInfo.isConnected) {
        _syncInBackground(userId);
      }

      return Right(profile);
    } on CacheException catch (e) {
      // If not in local, try to fetch from remote
      if (await networkInfo.isConnected) {
        return syncProfile(userId).then((result) {
          return result.fold(
            (failure) => Left(failure),
            (_) => getProfile(userId),
          );
        });
      }
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile>> updateProfile({
    required String userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? preferredUnits,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      final profile = await remoteDataSource.updateProfile(
        userId: userId,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
        preferredUnits: preferredUnits,
      );

      // Update local cache
      await localDataSource.upsertProfile(profile);

      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Profile?> watchProfile(String userId) {
    return localDataSource.watchProfile(userId);
  }

  @override
  Future<Either<Failure, void>> syncProfile(String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      final profile = await remoteDataSource.fetchProfile(userId);
      await localDataSource.upsertProfile(profile);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  void _syncInBackground(String userId) {
    syncProfile(userId);
  }
}
