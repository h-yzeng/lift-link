import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';

/// Repository interface for friendship operations
abstract class FriendshipRepository {
  /// Send a friend request to another user
  Future<Either<Failure, Friendship>> sendFriendRequest({
    required String currentUserId,
    required String targetUserId,
  });

  /// Accept a friend request
  Future<Either<Failure, Friendship>> acceptFriendRequest({
    required String currentUserId,
    required String friendshipId,
  });

  /// Reject a friend request
  Future<Either<Failure, Friendship>> rejectFriendRequest({
    required String currentUserId,
    required String friendshipId,
  });

  /// Remove a friend or cancel a pending request
  Future<Either<Failure, void>> removeFriendship({
    required String currentUserId,
    required String friendshipId,
  });

  /// Get all accepted friends for the current user
  Future<Either<Failure, List<Friendship>>> getFriends(String userId);

  /// Get all pending friend requests (both sent and received)
  Future<Either<Failure, List<Friendship>>> getPendingRequests(String userId);

  /// Get received friend requests (requests that the user can accept/reject)
  Future<Either<Failure, List<Friendship>>> getReceivedRequests(String userId);

  /// Get sent friend requests (requests that the user sent)
  Future<Either<Failure, List<Friendship>>> getSentRequests(String userId);

  /// Check if a friendship exists between two users
  Future<Either<Failure, Friendship?>> getFriendshipBetweenUsers({
    required String userId1,
    required String userId2,
  });

  /// Watch friendships changes (for real-time updates)
  Stream<List<Friendship>> watchFriendships(String userId);

  /// Sync friendships from remote
  Future<Either<Failure, void>> syncFriendships(String userId);

  /// Update nickname for a friend
  Future<Either<Failure, Friendship>> updateFriendNickname({
    required String currentUserId,
    required String friendshipId,
    required String nickname,
  });
}
