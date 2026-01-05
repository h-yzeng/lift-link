import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_queue_item.freezed.dart';
part 'sync_queue_item.g.dart';

/// Types of sync operations
enum SyncOperationType { create, update, delete }

/// Types of entities that can be synced
enum SyncEntityType { workout, set, exercise, profile, friendship }

/// Represents a pending sync operation in the queue
@freezed
abstract class SyncQueueItem with _$SyncQueueItem {
  const factory SyncQueueItem({
    required String id,
    required String userId,
    required SyncOperationType operationType,
    required SyncEntityType entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    @Default(0) int retryCount,
    @Default(5) int maxRetries,
    DateTime? nextRetryAt,
    String? lastError,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SyncQueueItem;

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) =>
      _$SyncQueueItemFromJson(json);
}

extension SyncQueueItemX on SyncQueueItem {
  /// Whether this item is ready to be retried
  bool get isReadyForRetry {
    if (retryCount >= maxRetries) return false;
    if (nextRetryAt == null) return true;
    return DateTime.now().isAfter(nextRetryAt!);
  }

  /// Whether this item has exceeded max retries
  bool get hasExceededMaxRetries => retryCount >= maxRetries;

  /// Calculate next retry delay using exponential backoff
  /// Base delay: 5 seconds
  /// Max delay: 5 minutes
  Duration calculateNextRetryDelay() {
    const baseDelaySeconds = 5;
    const maxDelaySeconds = 300; // 5 minutes

    // Exponential backoff: 5s, 10s, 20s, 40s, 80s, 160s (capped at 300s)
    final delaySeconds = (baseDelaySeconds * (1 << retryCount)).clamp(
      baseDelaySeconds,
      maxDelaySeconds,
    );

    return Duration(seconds: delaySeconds);
  }

  /// Create a new retry attempt with updated retry count and next retry time
  SyncQueueItem withRetryAttempt(String error) {
    final newRetryCount = retryCount + 1;
    final nextDelay = calculateNextRetryDelay();

    return copyWith(
      retryCount: newRetryCount,
      nextRetryAt: DateTime.now().add(nextDelay),
      lastError: error,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark this item as successfully synced (for deletion)
  SyncQueueItem markAsCompleted() {
    return copyWith(updatedAt: DateTime.now());
  }
}
