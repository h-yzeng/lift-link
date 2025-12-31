import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/domain/repositories/auth_repository.dart';

/// Use case for updating the current user's password.
class UpdatePassword {
  final AuthRepository repository;

  UpdatePassword(this.repository);

  /// Updates the password for the currently authenticated user.
  ///
  /// Returns [void] on success or a [Failure] if the request fails.
  Future<Either<Failure, void>> call(String newPassword) async {
    // Validate password
    if (newPassword.isEmpty) {
      return const Left(Failure.validation(message: 'Password cannot be empty'));
    }

    if (newPassword.length < 6) {
      return const Left(Failure.validation(message: 'Password must be at least 6 characters'));
    }

    return await repository.updatePassword(newPassword: newPassword);
  }
}
