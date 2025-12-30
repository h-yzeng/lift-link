import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/domain/repositories/friendship_repository.dart';

/// Use case for sending a friend request to another user.
class SendFriendRequest {
  final FriendshipRepository repository;

  SendFriendRequest(this.repository);

  /// Sends a friend request from [currentUserId] to [targetUserId].
  ///
  /// Returns a [Friendship] on success or a [Failure] if the request fails.
  Future<Either<Failure, Friendship>> call({
    required String currentUserId,
    required String targetUserId,
  }) async {
    // Validate that user isn't trying to friend themselves
    if (currentUserId == targetUserId) {
      return const Left(Failure.validation(message: 'Cannot send friend request to yourself'));
    }

    return await repository.sendFriendRequest(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );
  }
}
