import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/domain/entities/user.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Get the currently authenticated user
  /// Returns [User] if authenticated, null if not authenticated
  Future<Either<Failure, User?>> getCurrentUser();

  /// Sign in with email and password
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  });

  /// Register a new user with email and password
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<Either<Failure, void>> logout();

  /// Stream of authentication state changes
  /// Emits User when signed in, null when signed out
  Stream<User?> get authStateChanges;

  /// Reset password for given email
  Future<Either<Failure, void>> resetPassword({
    required String email,
  });

  /// Update user password (requires current session)
  Future<Either<Failure, void>> updatePassword({
    required String newPassword,
  });
}
