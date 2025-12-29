import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/domain/repositories/auth_repository.dart';

/// Use case for logging out the current user
class Logout {
  final AuthRepository repository;

  Logout(this.repository);

  Future<Either<Failure, void>> call() async {
    return repository.logout();
  }
}
