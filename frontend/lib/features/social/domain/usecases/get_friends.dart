import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/domain/repositories/friendship_repository.dart';

/// Use case for getting all accepted friends for a user.
class GetFriends {
  final FriendshipRepository repository;

  GetFriends(this.repository);

  /// Gets all accepted friends for the given [userId].
  ///
  /// Returns a list of [Friendship] objects on success or a [Failure] if the request fails.
  Future<Either<Failure, List<Friendship>>> call(String userId) async {
    return await repository.getFriends(userId);
  }
}
