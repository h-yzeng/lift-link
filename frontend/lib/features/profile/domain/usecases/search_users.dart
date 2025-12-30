import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/profile/domain/repositories/profile_repository.dart';

/// Use case for searching users by username or display name.
class SearchUsers {
  final ProfileRepository repository;

  SearchUsers(this.repository);

  /// Searches for users matching the [query].
  ///
  /// Returns a list of [Profile] objects on success or a [Failure] if the request fails.
  /// The [limit] parameter controls the maximum number of results (default 20).
  Future<Either<Failure, List<Profile>>> call({
    required String query,
    int limit = 20,
  }) async {
    // Validate query is not empty
    if (query.trim().isEmpty) {
      return const Left(Failure.validation(message: 'Search query cannot be empty'));
    }

    return await repository.searchUsers(
      query: query.trim(),
      limit: limit,
    );
  }
}
