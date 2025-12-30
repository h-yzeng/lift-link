import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/domain/repositories/friendship_repository.dart';

/// Use case for getting all pending friend requests (sent and received).
class GetPendingRequests {
  final FriendshipRepository repository;

  GetPendingRequests(this.repository);

  /// Gets all pending friend requests for the given [userId].
  ///
  /// Returns a list of [Friendship] objects on success or a [Failure] if the request fails.
  Future<Either<Failure, List<Friendship>>> call(String userId) async {
    return await repository.getPendingRequests(userId);
  }
}
