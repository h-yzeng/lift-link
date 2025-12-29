import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/domain/entities/user.dart';
import 'package:liftlink/features/auth/domain/repositories/auth_repository.dart';

/// Use case for logging in with email and password
class LoginWithEmail {
  final AuthRepository repository;

  LoginWithEmail(this.repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) async {
    // Basic validation
    if (email.isEmpty || !_isValidEmail(email)) {
      return const Left(ValidationFailure(message: 'Invalid email address'));
    }

    if (password.isEmpty || password.length < 6) {
      return const Left(
        ValidationFailure(message: 'Password must be at least 6 characters'),
      );
    }

    return repository.loginWithEmail(email: email, password: password);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
