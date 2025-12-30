import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/domain/repositories/friendship_repository.dart';

/// Use case for accepting a friend request.
class AcceptFriendRequest {
  final FriendshipRepository repository;

  AcceptFriendRequest(this.repository);

  /// Accepts the friend request with [friendshipId].
  ///
  /// Returns the updated [Friendship] on success or a [Failure] if the request fails.
  Future<Either<Failure, Friendship>> call({
    required String currentUserId,
    required String friendshipId,
  }) async {
    return await repository.acceptFriendRequest(
      currentUserId: currentUserId,
      friendshipId: friendshipId,
    );
  }
}
