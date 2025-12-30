import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';

/// Repository interface for profile operations
abstract class ProfileRepository {
  /// Get the current user's profile
  Future<Either<Failure, Profile>> getProfile(String userId);

  /// Update the current user's profile
  Future<Either<Failure, Profile>> updateProfile({
    required String userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? preferredUnits,
  });

  /// Watch profile changes (for real-time updates)
  Stream<Profile?> watchProfile(String userId);

  /// Sync profile from remote
  Future<Either<Failure, void>> syncProfile(String userId);

  /// Search for users by username or display name
  Future<Either<Failure, List<Profile>>> searchUsers({
    required String query,
    int limit = 20,
  });
}
