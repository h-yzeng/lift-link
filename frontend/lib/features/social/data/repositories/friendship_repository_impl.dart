import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/features/social/data/datasources/friendship_local_datasource.dart';
import 'package:liftlink/features/social/data/datasources/friendship_remote_datasource.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/domain/repositories/friendship_repository.dart';
import 'package:uuid/uuid.dart';

/// Implementation of FriendshipRepository with offline-first approach.
///
/// Read operations always read from local database.
/// Write operations write to local first, then sync to remote when online.
class FriendshipRepositoryImpl implements FriendshipRepository {
  final FriendshipLocalDataSource localDataSource;
  final FriendshipRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  FriendshipRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Friendship>> sendFriendRequest({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      // Check if friendship already exists
      final existing = await localDataSource.getFriendshipBetweenUsers(
        userId1: currentUserId,
        userId2: targetUserId,
      );

      if (existing != null) {
        return const Left(
            Failure.validation(message: 'Friendship already exists'),);
      }

      // Create new friendship
      final friendship = Friendship(
        id: const Uuid().v4(),
        requesterId: currentUserId,
        addresseeId: targetUserId,
        status: FriendshipStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save locally first
      await localDataSource.insertFriendship(friendship);

      // Try to sync to remote if online
      if (await networkInfo.isConnected) {
        try {
          final remoteFriendship = await remoteDataSource.sendFriendRequest(
            requesterId: currentUserId,
            addresseeId: targetUserId,
          );

          // Update local with remote data and mark as synced
          await localDataSource.updateFriendship(remoteFriendship);
          await localDataSource.markAsSynced(remoteFriendship.id);

          return Right(remoteFriendship);
        } catch (e) {
          // Remote failed but local succeeded, will sync later
          return Right(friendship);
        }
      }

      return Right(friendship);
    } on ServerException {
      return const Left(ServerFailure());
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Friendship>> acceptFriendRequest({
    required String currentUserId,
    required String friendshipId,
  }) async {
    try {
      // Get the friendship
      final friendship = await localDataSource.getFriendshipById(friendshipId);
      if (friendship == null) {
        return const Left(Failure.notFound(message: 'Friendship not found'));
      }

      // Validate that current user is the addressee
      if (friendship.addresseeId != currentUserId) {
        return const Left(Failure.validation(
            message: 'Cannot accept request you did not receive',),);
      }

      // Validate that the friendship is pending
      if (!friendship.isPending) {
        return const Left(
            Failure.validation(message: 'Friendship is not pending',),);
      }

      // Update the friendship status
      final updatedFriendship = Friendship(
        id: friendship.id,
        requesterId: friendship.requesterId,
        addresseeId: friendship.addresseeId,
        status: FriendshipStatus.accepted,
        createdAt: friendship.createdAt,
        updatedAt: DateTime.now(),
      );

      // Save locally first
      await localDataSource.updateFriendship(updatedFriendship);

      // Try to sync to remote if online
      if (await networkInfo.isConnected) {
        try {
          final remoteFriendship = await remoteDataSource.acceptFriendRequest(
            friendshipId,
          );

          // Update local with remote data and mark as synced
          await localDataSource.updateFriendship(remoteFriendship);
          await localDataSource.markAsSynced(remoteFriendship.id);

          return Right(remoteFriendship);
        } catch (e) {
          // Remote failed but local succeeded, will sync later
          return Right(updatedFriendship);
        }
      }

      return Right(updatedFriendship);
    } on ServerException {
      return const Left(ServerFailure());
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Friendship>> rejectFriendRequest({
    required String currentUserId,
    required String friendshipId,
  }) async {
    try {
      // Get the friendship
      final friendship = await localDataSource.getFriendshipById(friendshipId);
      if (friendship == null) {
        return const Left(Failure.notFound(message: 'Friendship not found'));
      }

      // Validate that current user is the addressee
      if (friendship.addresseeId != currentUserId) {
        return const Left(Failure.validation(
            message: 'Cannot reject request you did not receive',),);
      }

      // Validate that the friendship is pending
      if (!friendship.isPending) {
        return const Left(
            Failure.validation(message: 'Friendship is not pending',),);
      }

      // Update the friendship status
      final updatedFriendship = Friendship(
        id: friendship.id,
        requesterId: friendship.requesterId,
        addresseeId: friendship.addresseeId,
        status: FriendshipStatus.rejected,
        createdAt: friendship.createdAt,
        updatedAt: DateTime.now(),
      );

      // Save locally first
      await localDataSource.updateFriendship(updatedFriendship);

      // Try to sync to remote if online
      if (await networkInfo.isConnected) {
        try {
          final remoteFriendship = await remoteDataSource.rejectFriendRequest(
            friendshipId,
          );

          // Update local with remote data and mark as synced
          await localDataSource.updateFriendship(remoteFriendship);
          await localDataSource.markAsSynced(remoteFriendship.id);

          return Right(remoteFriendship);
        } catch (e) {
          // Remote failed but local succeeded, will sync later
          return Right(updatedFriendship);
        }
      }

      return Right(updatedFriendship);
    } on ServerException {
      return const Left(ServerFailure());
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFriendship({
    required String currentUserId,
    required String friendshipId,
  }) async {
    try {
      // Get the friendship
      final friendship = await localDataSource.getFriendshipById(friendshipId);
      if (friendship == null) {
        return const Left(Failure.notFound(message: 'Friendship not found'));
      }

      // Validate that current user is involved in the friendship
      if (friendship.requesterId != currentUserId &&
          friendship.addresseeId != currentUserId) {
        return const Left(Failure.validation(
            message: 'Cannot remove friendship you are not part of',),);
      }

      // Delete locally first
      await localDataSource.deleteFriendship(friendshipId);

      // Try to sync to remote if online
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.deleteFriendship(friendshipId);
        } catch (e) {
          // Remote failed but local succeeded, will sync later
        }
      }

      return const Right(null);
    } on ServerException {
      return const Left(ServerFailure());
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Friendship>>> getFriends(String userId) async {
    try {
      // Always read from local database (offline-first)
      final friendships = await localDataSource.getFriends(userId);
      return Right(friendships);
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Friendship>>> getPendingRequests(
    String userId,
  ) async {
    try {
      // Always read from local database (offline-first)
      final friendships = await localDataSource.getPendingRequests(userId);
      return Right(friendships);
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Friendship>>> getReceivedRequests(
    String userId,
  ) async {
    try {
      // Always read from local database (offline-first)
      final friendships = await localDataSource.getReceivedRequests(userId);
      return Right(friendships);
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Friendship>>> getSentRequests(
    String userId,
  ) async {
    try {
      // Always read from local database (offline-first)
      final friendships = await localDataSource.getSentRequests(userId);
      return Right(friendships);
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Friendship?>> getFriendshipBetweenUsers({
    required String userId1,
    required String userId2,
  }) async {
    try {
      // Always read from local database (offline-first)
      final friendship = await localDataSource.getFriendshipBetweenUsers(
        userId1: userId1,
        userId2: userId2,
      );
      return Right(friendship);
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Stream<List<Friendship>> watchFriendships(String userId) {
    return localDataSource.watchFriendships(userId);
  }

  @override
  Future<Either<Failure, void>> syncFriendships(String userId) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }

      // Fetch friendships from remote
      final remoteFriendships =
          await remoteDataSource.getAllFriendships(userId);

      // Update local database
      for (final friendship in remoteFriendships) {
        final existing = await localDataSource.getFriendshipById(friendship.id);

        if (existing == null) {
          // Insert new friendship
          await localDataSource.insertFriendship(friendship);
        } else {
          // Update existing friendship
          await localDataSource.updateFriendship(friendship);
        }

        // Mark as synced
        await localDataSource.markAsSynced(friendship.id);
      }

      return const Right(null);
    } on ServerException {
      return const Left(ServerFailure());
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Friendship>> updateFriendNickname({
    required String currentUserId,
    required String friendshipId,
    required String nickname,
  }) async {
    try {
      // Get the friendship
      final friendship = await localDataSource.getFriendshipById(friendshipId);
      if (friendship == null) {
        return const Left(Failure.notFound(message: 'Friendship not found'));
      }

      // Validate that current user is involved in the friendship
      if (friendship.requesterId != currentUserId &&
          friendship.addresseeId != currentUserId) {
        return const Left(Failure.validation(
            message: 'Cannot update friendship you are not part of',),);
      }

      // Determine which nickname to update based on current user's role
      final updatedFriendship = friendship.requesterId == currentUserId
          ? friendship.copyWith(
              requesterNickname: nickname.isEmpty ? null : nickname,
              updatedAt: DateTime.now(),
            )
          : friendship.copyWith(
              addresseeNickname: nickname.isEmpty ? null : nickname,
              updatedAt: DateTime.now(),
            );

      // Save locally first
      await localDataSource.updateFriendship(updatedFriendship);

      // Try to sync to remote if online
      if (await networkInfo.isConnected) {
        try {
          final remoteFriendship = await remoteDataSource.updateFriendNickname(
            friendshipId: friendshipId,
            requesterNickname: updatedFriendship.requesterNickname,
            addresseeNickname: updatedFriendship.addresseeNickname,
          );

          // Update local with remote data and mark as synced
          await localDataSource.updateFriendship(remoteFriendship);
          await localDataSource.markAsSynced(remoteFriendship.id);

          return Right(remoteFriendship);
        } catch (e) {
          // Remote failed but local succeeded, will sync later
          return Right(updatedFriendship);
        }
      }

      return Right(updatedFriendship);
    } on ServerException {
      return const Left(ServerFailure());
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Friendship>>> getFriendsPaginated({
    required String userId,
    required int limit,
    required int offset,
  }) async {
    try {
      // For now, get all friends and apply pagination in memory
      // TODO: Optimize by adding LIMIT/OFFSET support to local data source
      final allFriendships = await localDataSource.getFriends(userId);

      final startIndex = offset;
      final endIndex = offset + limit;

      if (startIndex >= allFriendships.length) {
        return const Right([]);
      }

      final paginatedFriendships = allFriendships.sublist(
        startIndex,
        endIndex > allFriendships.length ? allFriendships.length : endIndex,
      );

      return Right(paginatedFriendships);
    } on CacheException {
      return const Left(CacheFailure());
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }
}
