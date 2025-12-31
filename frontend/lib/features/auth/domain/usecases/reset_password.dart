import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/domain/repositories/auth_repository.dart';

/// Use case for sending a password reset email.
class ResetPassword {
  final AuthRepository repository;

  ResetPassword(this.repository);

  /// Sends a password reset email to the specified email address.
  ///
  /// Returns [void] on success or a [Failure] if the request fails.
  Future<Either<Failure, void>> call(String email) async {
    // Validate email
    if (email.isEmpty) {
      return const Left(Failure.validation(message: 'Email cannot be empty'));
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return const Left(Failure.validation(message: 'Invalid email address'));
    }

    return await repository.resetPassword(email: email);
  }
}
