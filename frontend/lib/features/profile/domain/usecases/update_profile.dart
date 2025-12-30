import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/profile/domain/repositories/profile_repository.dart';

/// Parameters for updating profile
class UpdateProfileParams {
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? preferredUnits;

  UpdateProfileParams({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.preferredUnits,
  });
}

/// Use case for updating user profile
class UpdateProfile {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  Future<Either<Failure, Profile>> call(UpdateProfileParams params) {
    return repository.updateProfile(
      userId: params.userId,
      username: params.username,
      displayName: params.displayName,
      avatarUrl: params.avatarUrl,
      bio: params.bio,
      preferredUnits: params.preferredUnits,
    );
  }
}
