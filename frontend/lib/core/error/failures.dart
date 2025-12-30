import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Represents a failure that can occur in the application.
///
/// Uses freezed sealed class for exhaustive pattern matching.
@freezed
sealed class Failure with _$Failure {
  /// A failure that occurred during a server request.
  const factory Failure.server({
    String? message,
    int? statusCode,
  }) = ServerFailure;

  /// A failure that occurred while accessing the local cache.
  const factory Failure.cache({
    String? message,
  }) = CacheFailure;

  /// A failure due to no network connection.
  const factory Failure.network({
    String? message,
  }) = NetworkFailure;

  /// A failure during authentication.
  const factory Failure.auth({
    String? message,
    String? code,
  }) = AuthFailure;

  /// A failure due to validation errors.
  const factory Failure.validation({
    required String message,
    Map<String, List<String>>? fieldErrors,
  }) = ValidationFailure;

  /// A failure during sync operations.
  const factory Failure.sync({
    String? message,
    List<String>? failedIds,
  }) = SyncFailure;

  /// A failure when a requested resource is not found.
  const factory Failure.notFound({
    required String message,
  }) = NotFoundFailure;

  /// An unexpected failure.
  const factory Failure.unexpected({
    required String message,
  }) = UnexpectedFailure;
}

/// Extension methods for Failure
extension FailureX on Failure {
  /// Get a user-friendly error message
  String get userMessage => when(
        server: (message, statusCode) =>
            message ?? 'Something went wrong. Please try again.',
        cache: (message) =>
            message ?? 'Failed to load saved data.',
        network: (message) =>
            message ?? 'No internet connection. Please check your network.',
        auth: (message, code) =>
            message ?? 'Authentication failed. Please sign in again.',
        validation: (message, fieldErrors) => message,
        sync: (message, failedIds) =>
            message ?? 'Failed to sync data. Will retry when online.',
        notFound: (message) => message,
        unexpected: (message) => message,
      );

  /// Whether this failure should trigger a retry
  bool get isRetryable => when(
        server: (_, statusCode) =>
            statusCode == null || statusCode >= 500 || statusCode == 429,
        cache: (_) => true,
        network: (_) => true,
        auth: (_, __) => false,
        validation: (_, __) => false,
        sync: (_, __) => true,
        notFound: (_) => false,
        unexpected: (_) => false,
      );
}
