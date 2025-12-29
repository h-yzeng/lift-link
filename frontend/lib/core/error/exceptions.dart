/// Exception thrown when a server request fails.
class ServerException implements Exception {
  final String? message;
  final int? statusCode;

  const ServerException({this.message, this.statusCode});

  @override
  String toString() =>
      'ServerException: ${message ?? 'Unknown server error'} (status: $statusCode)';
}

/// Exception thrown when a cache operation fails.
class CacheException implements Exception {
  final String? message;

  const CacheException({this.message});

  @override
  String toString() =>
      'CacheException: ${message ?? 'Failed to access local cache'}';
}

/// Exception thrown when there's no network connection.
class NetworkException implements Exception {
  final String? message;

  const NetworkException({this.message});

  @override
  String toString() =>
      'NetworkException: ${message ?? 'No network connection'}';
}

/// Exception thrown for authentication failures.
class AuthException implements Exception {
  final String? message;
  final String? code;

  const AuthException({this.message, this.code});

  @override
  String toString() =>
      'AuthException: ${message ?? 'Authentication failed'} (code: $code)';
}

/// Exception thrown for validation failures.
class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? fieldErrors;

  const ValidationException(this.message, {this.fieldErrors});

  @override
  String toString() => 'ValidationException: $message';

  /// Whether this validation has field-specific errors
  bool get hasFieldErrors => fieldErrors != null && fieldErrors!.isNotEmpty;

  /// Get errors for a specific field
  List<String> errorsForField(String field) => fieldErrors?[field] ?? [];
}

/// Exception thrown when a sync operation fails.
class SyncException implements Exception {
  final String? message;
  final List<String>? failedIds;

  const SyncException({this.message, this.failedIds});

  @override
  String toString() =>
      'SyncException: ${message ?? 'Sync operation failed'}';
}
