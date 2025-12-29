import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/domain/entities/user.dart';
import 'package:liftlink/features/auth/domain/repositories/auth_repository.dart';

/// Use case for registering a new user with email and password
class RegisterWithEmail {
  final AuthRepository repository;

  RegisterWithEmail(this.repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // Validation
    if (email.isEmpty || !_isValidEmail(email)) {
      return const Left(ValidationFailure(message: 'Invalid email address'));
    }

    if (password.isEmpty || password.length < 6) {
      return const Left(
        ValidationFailure(message: 'Password must be at least 6 characters'),
      );
    }

    if (password != confirmPassword) {
      return const Left(
        ValidationFailure(message: 'Passwords do not match'),
      );
    }

    return repository.registerWithEmail(email: email, password: password);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
