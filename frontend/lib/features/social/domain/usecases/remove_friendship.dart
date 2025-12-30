import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/social/domain/repositories/friendship_repository.dart';

/// Use case for removing a friendship or canceling a pending friend request.
class RemoveFriendship {
  final FriendshipRepository repository;

  RemoveFriendship(this.repository);

  /// Removes the friendship with [friendshipId].
  ///
  /// Returns void on success or a [Failure] if the request fails.
  Future<Either<Failure, void>> call({
    required String currentUserId,
    required String friendshipId,
  }) async {
    return await repository.removeFriendship(
      currentUserId: currentUserId,
      friendshipId: friendshipId,
    );
  }
}
