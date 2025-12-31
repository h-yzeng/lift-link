import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/domain/repositories/friendship_repository.dart';

/// Use case for updating a friend's nickname.
class UpdateFriendNickname {
  final FriendshipRepository repository;

  UpdateFriendNickname(this.repository);

  /// Updates the nickname for a friend.
  ///
  /// Returns the updated [Friendship] on success or a [Failure] if the request fails.
  Future<Either<Failure, Friendship>> call({
    required String currentUserId,
    required String friendshipId,
    required String nickname,
  }) async {
    // Validate nickname length if not empty
    if (nickname.isNotEmpty && nickname.length > 50) {
      return const Left(Failure.validation(message: 'Nickname must be 50 characters or less'));
    }

    return await repository.updateFriendNickname(
      currentUserId: currentUserId,
      friendshipId: friendshipId,
      nickname: nickname,
    );
  }
}
