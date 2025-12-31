import 'package:liftlink/features/social/data/models/friendship_model.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for friendships using Supabase.
class FriendshipRemoteDataSource {
  final SupabaseClient client;

  FriendshipRemoteDataSource(this.client);

  /// Send a friend request
  Future<Friendship> sendFriendRequest({
    required String requesterId,
    required String addresseeId,
  }) async {
    final data = {
      'requester_id': requesterId,
      'addressee_id': addresseeId,
      'status': 'pending',
    };

    final response = await client
        .from('friendships')
        .insert(data)
        .select()
        .single();

    return FriendshipModel.fromSupabase(response);
  }

  /// Accept a friend request
  Future<Friendship> acceptFriendRequest(String friendshipId) async {
    final data = {
      'status': 'accepted',
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await client
        .from('friendships')
        .update(data)
        .eq('id', friendshipId)
        .select()
        .single();

    return FriendshipModel.fromSupabase(response);
  }

  /// Reject a friend request
  Future<Friendship> rejectFriendRequest(String friendshipId) async {
    final data = {
      'status': 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await client
        .from('friendships')
        .update(data)
        .eq('id', friendshipId)
        .select()
        .single();

    return FriendshipModel.fromSupabase(response);
  }

  /// Delete a friendship
  Future<void> deleteFriendship(String friendshipId) async {
    await client
        .from('friendships')
        .delete()
        .eq('id', friendshipId);
  }

  /// Get all friendships for a user
  Future<List<Friendship>> getAllFriendships(String userId) async {
    final response = await client
        .from('friendships')
        .select()
        .or('requester_id.eq.$userId,addressee_id.eq.$userId')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FriendshipModel.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// Get accepted friends for a user
  Future<List<Friendship>> getFriends(String userId) async {
    final response = await client
        .from('friendships')
        .select()
        .or('requester_id.eq.$userId,addressee_id.eq.$userId')
        .eq('status', 'accepted')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FriendshipModel.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// Get pending friend requests (both sent and received)
  Future<List<Friendship>> getPendingRequests(String userId) async {
    final response = await client
        .from('friendships')
        .select()
        .or('requester_id.eq.$userId,addressee_id.eq.$userId')
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FriendshipModel.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// Get received friend requests (where user is addressee)
  Future<List<Friendship>> getReceivedRequests(String userId) async {
    final response = await client
        .from('friendships')
        .select()
        .eq('addressee_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FriendshipModel.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// Get sent friend requests (where user is requester)
  Future<List<Friendship>> getSentRequests(String userId) async {
    final response = await client
        .from('friendships')
        .select()
        .eq('requester_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FriendshipModel.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  /// Get friendship between two users
  Future<Friendship?> getFriendshipBetweenUsers({
    required String userId1,
    required String userId2,
  }) async {
    final response = await client
        .from('friendships')
        .select()
        .or('and(requester_id.eq.$userId1,addressee_id.eq.$userId2),and(requester_id.eq.$userId2,addressee_id.eq.$userId1)')
        .maybeSingle();

    return response != null ? FriendshipModel.fromSupabase(response) : null;
  }

  /// Get friendship by ID
  Future<Friendship?> getFriendshipById(String friendshipId) async {
    final response = await client
        .from('friendships')
        .select()
        .eq('id', friendshipId)
        .maybeSingle();

    return response != null ? FriendshipModel.fromSupabase(response) : null;
  }

  /// Update friend nickname
  Future<Friendship> updateFriendNickname({
    required String friendshipId,
    String? requesterNickname,
    String? addresseeNickname,
  }) async {
    final data = {
      'requester_nickname': requesterNickname,
      'addressee_nickname': addresseeNickname,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await client
        .from('friendships')
        .update(data)
        .eq('id', friendshipId)
        .select()
        .single();

    return FriendshipModel.fromSupabase(response);
  }
}
