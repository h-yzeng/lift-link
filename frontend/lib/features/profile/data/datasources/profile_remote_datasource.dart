import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Remote data source for profiles using Supabase
abstract class ProfileRemoteDataSource {
  /// Fetch profile from Supabase
  Future<Profile> fetchProfile(String userId);

  /// Update profile in Supabase
  Future<Profile> updateProfile({
    required String userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? preferredUnits,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final supabase.SupabaseClient supabaseClient;

  ProfileRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<Profile> fetchProfile(String userId) async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return _profileFromJson(response);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Profile> updateProfile({
    required String userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? preferredUnits,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (username != null) updates['username'] = username;
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;
      if (preferredUnits != null) updates['preferred_units'] = preferredUnits;

      final response = await supabaseClient
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return _profileFromJson(response);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Profile _profileFromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      preferredUnits: json['preferred_units'] as String? ?? 'imperial',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
