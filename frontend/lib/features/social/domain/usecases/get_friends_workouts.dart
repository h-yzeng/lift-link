import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/social/domain/repositories/friendship_repository.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case for getting recent workouts from all friends.
class GetFriendsWorkouts {
  final FriendshipRepository friendshipRepository;
  final WorkoutRepository workoutRepository;

  GetFriendsWorkouts({
    required this.friendshipRepository,
    required this.workoutRepository,
  });

  /// Gets recent workouts from all friends.
  ///
  /// Returns a list of workout sessions from friends, sorted by date.
  /// The [limit] parameter controls how many workouts to fetch per friend.
  Future<Either<Failure, List<WorkoutSession>>> call({
    required String userId,
    int limit = 10,
  }) async {
    // Get all friends
    final friendsResult = await friendshipRepository.getFriends(userId);

    return friendsResult.fold(
      (failure) => Left(failure),
      (friendships) async {
        final allWorkouts = <WorkoutSession>[];

        // Get workouts for each friend
        for (final friendship in friendships) {
          final friendId = friendship.getOtherUserId(userId);

          final workoutsResult = await workoutRepository.getWorkoutHistory(
            userId: friendId,
            limit: limit,
          );

          workoutsResult.fold(
            (_) {}, // Ignore failures for individual friends
            (workouts) => allWorkouts.addAll(workouts),
          );
        }

        // Sort by date (most recent first)
        allWorkouts.sort((a, b) => b.startedAt.compareTo(a.startedAt));

        // Limit total results
        final limitedWorkouts = allWorkouts.take(limit * 2).toList();

        return Right(limitedWorkouts);
      },
    );
  }
}
