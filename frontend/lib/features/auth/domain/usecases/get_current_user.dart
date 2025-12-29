import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/domain/entities/user.dart';
import 'package:liftlink/features/auth/domain/repositories/auth_repository.dart';

/// Use case for getting the currently authenticated user
class GetCurrentUser {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  Future<Either<Failure, User?>> call() async {
    return repository.getCurrentUser();
  }

  /// Get auth state changes as a stream
  Stream<User?> get authStateChanges => repository.authStateChanges;
}
