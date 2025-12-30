import 'package:liftlink/core/network/network_info_provider.dart';
import 'package:liftlink/features/social/data/datasources/friendship_local_datasource.dart';
import 'package:liftlink/features/social/data/datasources/friendship_remote_datasource.dart';
import 'package:liftlink/features/social/data/repositories/friendship_repository_impl.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/domain/repositories/friendship_repository.dart';
import 'package:liftlink/features/social/domain/usecases/accept_friend_request.dart';
import 'package:liftlink/features/social/domain/usecases/get_friends.dart';
import 'package:liftlink/features/social/domain/usecases/get_pending_requests.dart';
import 'package:liftlink/features/social/domain/usecases/reject_friend_request.dart';
import 'package:liftlink/features/social/domain/usecases/remove_friendship.dart';
import 'package:liftlink/features/social/domain/usecases/send_friend_request.dart';
import 'package:liftlink/shared/database/app_database.dart';
import 'package:liftlink/shared/supabase/supabase_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friendship_providers.g.dart';

// ============================================================================
// Data Sources
// ============================================================================

@riverpod
FriendshipLocalDataSource friendshipLocalDataSource(
  FriendshipLocalDataSourceRef ref,
) {
  final database = ref.watch(appDatabaseProvider);
  return FriendshipLocalDataSource(database);
}

@riverpod
FriendshipRemoteDataSource friendshipRemoteDataSource(
  FriendshipRemoteDataSourceRef ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return FriendshipRemoteDataSource(client);
}

// ============================================================================
// Repository
// ============================================================================

@riverpod
FriendshipRepository friendshipRepository(FriendshipRepositoryRef ref) {
  return FriendshipRepositoryImpl(
    localDataSource: ref.watch(friendshipLocalDataSourceProvider),
    remoteDataSource: ref.watch(friendshipRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
}

// ============================================================================
// Use Cases
// ============================================================================

@riverpod
SendFriendRequest sendFriendRequest(SendFriendRequestRef ref) {
  return SendFriendRequest(ref.watch(friendshipRepositoryProvider));
}

@riverpod
AcceptFriendRequest acceptFriendRequest(AcceptFriendRequestRef ref) {
  return AcceptFriendRequest(ref.watch(friendshipRepositoryProvider));
}

@riverpod
RejectFriendRequest rejectFriendRequest(RejectFriendRequestRef ref) {
  return RejectFriendRequest(ref.watch(friendshipRepositoryProvider));
}

@riverpod
RemoveFriendship removeFriendship(RemoveFriendshipRef ref) {
  return RemoveFriendship(ref.watch(friendshipRepositoryProvider));
}

@riverpod
GetFriends getFriends(GetFriendsRef ref) {
  return GetFriends(ref.watch(friendshipRepositoryProvider));
}

@riverpod
GetPendingRequests getPendingRequests(GetPendingRequestsRef ref) {
  return GetPendingRequests(ref.watch(friendshipRepositoryProvider));
}

// ============================================================================
// UI State Providers
// ============================================================================

/// Watch all friendships for the current user
@riverpod
Stream<List<Friendship>> watchFriendships(
  WatchFriendshipsRef ref,
  String userId,
) {
  final repository = ref.watch(friendshipRepositoryProvider);
  return repository.watchFriendships(userId);
}

/// Fetch friends list for the current user
@riverpod
Future<List<Friendship>> friendsList(FriendsListRef ref, String userId) async {
  final useCase = ref.watch(getFriendsProvider);
  final result = await useCase(userId);

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (friendships) => friendships,
  );
}

/// Fetch pending requests for the current user
@riverpod
Future<List<Friendship>> pendingRequestsList(
  PendingRequestsListRef ref,
  String userId,
) async {
  final useCase = ref.watch(getPendingRequestsProvider);
  final result = await useCase(userId);

  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (requests) => requests,
  );
}
