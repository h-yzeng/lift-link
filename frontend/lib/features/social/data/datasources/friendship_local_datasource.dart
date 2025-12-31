import 'package:drift/drift.dart';
import 'package:liftlink/features/social/data/models/friendship_model.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/shared/database/app_database.dart';

/// Local data source for friendships using Drift (SQLite).
class FriendshipLocalDataSource {
  final AppDatabase database;

  FriendshipLocalDataSource(this.database);

  /// Get all friendships for a user (where they are either requester or addressee)
  Future<List<Friendship>> getAllFriendships(String userId) async {
    final query = database.select(database.friendships)
      ..where(
        (f) => f.requesterId.equals(userId) | f.addresseeId.equals(userId),
      );

    final entities = await query.get();
    return entities.map(FriendshipModel.fromDrift).toList();
  }

  /// Get all accepted friends for a user
  Future<List<Friendship>> getFriends(String userId) async {
    final query = database.select(database.friendships)
      ..where(
        (f) =>
            (f.requesterId.equals(userId) | f.addresseeId.equals(userId)) &
            f.status.equals('accepted'),
      );

    final entities = await query.get();
    return entities.map(FriendshipModel.fromDrift).toList();
  }

  /// Get all pending friend requests (both sent and received)
  Future<List<Friendship>> getPendingRequests(String userId) async {
    final query = database.select(database.friendships)
      ..where(
        (f) =>
            (f.requesterId.equals(userId) | f.addresseeId.equals(userId)) &
            f.status.equals('pending'),
      );

    final entities = await query.get();
    return entities.map(FriendshipModel.fromDrift).toList();
  }

  /// Get received friend requests (where user is addressee)
  Future<List<Friendship>> getReceivedRequests(String userId) async {
    final query = database.select(database.friendships)
      ..where(
        (f) => f.addresseeId.equals(userId) & f.status.equals('pending'),
      );

    final entities = await query.get();
    return entities.map(FriendshipModel.fromDrift).toList();
  }

  /// Get sent friend requests (where user is requester)
  Future<List<Friendship>> getSentRequests(String userId) async {
    final query = database.select(database.friendships)
      ..where(
        (f) => f.requesterId.equals(userId) & f.status.equals('pending'),
      );

    final entities = await query.get();
    return entities.map(FriendshipModel.fromDrift).toList();
  }

  /// Get friendship by ID
  Future<Friendship?> getFriendshipById(String friendshipId) async {
    final query = database.select(database.friendships)
      ..where((f) => f.id.equals(friendshipId));

    final entity = await query.getSingleOrNull();
    return entity != null ? FriendshipModel.fromDrift(entity) : null;
  }

  /// Get friendship between two users (checks both directions)
  Future<Friendship?> getFriendshipBetweenUsers({
    required String userId1,
    required String userId2,
  }) async {
    final query = database.select(database.friendships)
      ..where(
        (f) =>
            (f.requesterId.equals(userId1) & f.addresseeId.equals(userId2)) |
            (f.requesterId.equals(userId2) & f.addresseeId.equals(userId1)),
      );

    final entity = await query.getSingleOrNull();
    return entity != null ? FriendshipModel.fromDrift(entity) : null;
  }

  /// Insert a new friendship
  Future<Friendship> insertFriendship(Friendship friendship) async {
    final companion = FriendshipModel.toDrift(friendship);
    await database.into(database.friendships).insert(companion);
    return friendship;
  }

  /// Update an existing friendship
  Future<Friendship> updateFriendship(Friendship friendship) async {
    final companion = FriendshipModel.toDrift(friendship, forUpdate: true);
    await (database.update(database.friendships)
          ..where((f) => f.id.equals(friendship.id)))
        .write(companion);
    return friendship;
  }

  /// Delete a friendship
  Future<void> deleteFriendship(String friendshipId) async {
    await (database.delete(database.friendships)
          ..where((f) => f.id.equals(friendshipId)))
        .go();
  }

  /// Mark friendship as synced
  Future<void> markAsSynced(String friendshipId) async {
    await (database.update(database.friendships)
          ..where((f) => f.id.equals(friendshipId)))
        .write(
      FriendshipsCompanion(
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Clear all friendships (for testing)
  Future<void> clearAll() async {
    await database.delete(database.friendships).go();
  }

  /// Watch friendships for a user (real-time updates)
  Stream<List<Friendship>> watchFriendships(String userId) {
    final query = database.select(database.friendships)
      ..where(
        (f) => f.requesterId.equals(userId) | f.addresseeId.equals(userId),
      );

    return query.watch().map(
          (entities) => entities.map(FriendshipModel.fromDrift).toList(),
        );
  }
}
