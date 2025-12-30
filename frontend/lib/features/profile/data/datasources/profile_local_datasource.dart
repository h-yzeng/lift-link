import 'package:drift/drift.dart';
import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/shared/database/app_database.dart';

/// Local data source for profiles using Drift
abstract class ProfileLocalDataSource {
  /// Get profile by user ID
  Future<Profile> getProfile(String userId);

  /// Update or insert profile
  Future<void> upsertProfile(Profile profile);

  /// Watch profile changes
  Stream<Profile?> watchProfile(String userId);
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final AppDatabase database;

  ProfileLocalDataSourceImpl({required this.database});

  @override
  Future<Profile> getProfile(String userId) async {
    try {
      final entity = await database.getProfile(userId);
      if (entity == null) {
        throw const CacheException(message: 'Profile not found');
      }
      return _entityToProfile(entity);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> upsertProfile(Profile profile) async {
    try {
      await database.upsertProfile(_profileToCompanion(profile));
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Stream<Profile?> watchProfile(String userId) {
    return database
        .watchProfile(userId)
        .map((entity) => entity != null ? _entityToProfile(entity) : null);
  }

  Profile _entityToProfile(ProfileEntity entity) {
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

  ProfilesCompanion _profileToCompanion(Profile profile) {
    return ProfilesCompanion.insert(
      id: profile.id,
      username: Value(profile.username),
      displayName: Value(profile.displayName),
      avatarUrl: Value(profile.avatarUrl),
      bio: Value(profile.bio),
      preferredUnits: Value(profile.preferredUnits),
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }
}
