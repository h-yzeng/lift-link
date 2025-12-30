import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/domain/repositories/friendship_repository.dart';

/// Use case for rejecting a friend request.
class RejectFriendRequest {
  final FriendshipRepository repository;

  RejectFriendRequest(this.repository);

  /// Rejects the friend request with [friendshipId].
  ///
  /// Returns the updated [Friendship] on success or a [Failure] if the request fails.
  Future<Either<Failure, Friendship>> call({
    required String currentUserId,
    required String friendshipId,
  }) async {
    return await repository.rejectFriendRequest(
      currentUserId: currentUserId,
      friendshipId: friendshipId,
    );
  }
}
