import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/profile/domain/repositories/profile_repository.dart';

/// Use case for getting user profile
class GetProfile {
  final ProfileRepository repository;

  GetProfile(this.repository);

  Future<Either<Failure, Profile>> call(String userId) {
    return repository.getProfile(userId);
  }
}
