import 'package:drift/drift.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/shared/database/app_database.dart';

/// Data model for Friendship that bridges between domain entity and database representations.
class FriendshipModel {
  /// Converts a Drift FriendshipEntity to a domain Friendship
  static Friendship fromDrift(FriendshipEntity entity) {
    return Friendship(
      id: entity.id,
      requesterId: entity.requesterId,
      addresseeId: entity.addresseeId,
      status: _statusFromString(entity.status),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converts a domain Friendship to a Drift FriendshipsCompanion for insert/update
  static FriendshipsCompanion toDrift(
    Friendship friendship, {
    bool forUpdate = false,
  }) {
    return FriendshipsCompanion.insert(
      id: friendship.id,
      requesterId: friendship.requesterId,
      addresseeId: friendship.addresseeId,
      status: _statusToString(friendship.status),
      createdAt: friendship.createdAt,
      updatedAt: friendship.updatedAt,
      syncedAt: const Value(null), // Will be set on successful sync
    );
  }

  /// Converts a Supabase JSON response to a domain Friendship
  static Friendship fromSupabase(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: _statusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts a domain Friendship to Supabase JSON for insert/update
  static Map<String, dynamic> toSupabase(
    Friendship friendship, {
    bool forUpdate = false,
  }) {
    final Map<String, dynamic> data = {
      'requester_id': friendship.requesterId,
      'addressee_id': friendship.addresseeId,
      'status': _statusToString(friendship.status),
    };

    if (!forUpdate) {
      data['id'] = friendship.id;
      data['created_at'] = friendship.createdAt.toIso8601String();
    }

    data['updated_at'] = friendship.updatedAt.toIso8601String();

    return data;
  }

  /// Convert FriendshipStatus enum to string
  static String _statusToString(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.pending:
        return 'pending';
      case FriendshipStatus.accepted:
        return 'accepted';
      case FriendshipStatus.rejected:
        return 'rejected';
    }
  }

  /// Convert string to FriendshipStatus enum
  static FriendshipStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return FriendshipStatus.pending;
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'rejected':
        return FriendshipStatus.rejected;
      default:
        throw ArgumentError('Invalid friendship status: $status');
    }
  }
}
