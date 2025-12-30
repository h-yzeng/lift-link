import 'package:drift/drift.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/shared/database/app_database.dart';

/// Data model for Profile that bridges between domain entity and database representations.
class ProfileModel {
  /// Converts a Drift ProfileEntity to a domain Profile
  static Profile fromDrift(ProfileEntity entity) {
    return Profile(
      id: entity.id,
      username: entity.username,
      displayName: entity.displayName,
      avatarUrl: entity.avatarUrl,
      bio: entity.bio,
      preferredUnits: entity.preferredUnits,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converts a domain Profile to a Drift ProfilesCompanion for insert/update
  static ProfilesCompanion toDrift(
    Profile profile, {
    bool forUpdate = false,
  }) {
    return ProfilesCompanion.insert(
      id: profile.id,
      username: Value(profile.username),
      displayName: Value(profile.displayName),
      avatarUrl: Value(profile.avatarUrl),
      bio: Value(profile.bio),
      preferredUnits: Value(profile.preferredUnits),
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      syncedAt: const Value(null), // Will be set on successful sync
    );
  }

  /// Converts a Supabase JSON response to a domain Profile
  static Profile fromSupabase(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      preferredUnits: (json['preferred_units'] as String?) ?? 'imperial',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts a domain Profile to Supabase JSON for insert/update
  static Map<String, dynamic> toSupabase(
    Profile profile, {
    bool forUpdate = false,
  }) {
    final Map<String, dynamic> data = {
      'username': profile.username,
      'display_name': profile.displayName,
      'avatar_url': profile.avatarUrl,
      'bio': profile.bio,
      'preferred_units': profile.preferredUnits,
    };

    if (!forUpdate) {
      data['id'] = profile.id;
      data['created_at'] = profile.createdAt.toIso8601String();
    }

    data['updated_at'] = profile.updatedAt.toIso8601String();

    return data;
  }
}
