import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/core/sync/sync_queue_item.dart';
import 'package:liftlink/core/sync/entity_merger.dart';
import 'package:liftlink/core/sync/merge_strategy.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/shared/database/app_database.dart';

/// Service for managing the offline sync queue with exponential backoff
class SyncQueueService {
  final NetworkInfo _networkInfo;
  final AppDatabase _database;
  final String userId;
  Timer? _retryTimer;
  bool _isProcessing = false;

  // Callbacks for different entity types
  final Map<SyncEntityType, Future<void> Function(SyncQueueItem)> _syncHandlers = {};

  SyncQueueService(this._networkInfo, this._database, this.userId);

  /// Register a sync handler for a specific entity type
  void registerSyncHandler(
    SyncEntityType entityType,
    Future<void> Function(SyncQueueItem item) handler,
  ) {
    _syncHandlers[entityType] = handler;
  }

  /// Start the retry timer to process pending items
  void startRetryTimer({Duration checkInterval = const Duration(seconds: 30)}) {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(checkInterval, (_) => processPendingItems());
  }

  /// Stop the retry timer
  void stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Process all pending sync queue items
  Future<void> processPendingItems() async {
    // Prevent concurrent processing
    if (_isProcessing) return;

    // Check network connectivity
    if (!await _networkInfo.isConnected) {
      return;
    }

    _isProcessing = true;

    try {
      // Get all pending items ready for retry
      final pendingItems = await _getPendingItemsForUser(userId);

      for (final item in pendingItems) {
        await _processSyncItem(item);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single sync queue item
  Future<void> _processSyncItem(SyncQueueItem item) async {
    // Skip if not ready for retry
    if (!item.isReadyForRetry) {
      return;
    }

    // Skip if no handler registered for this entity type
    final handler = _syncHandlers[item.entityType];
    if (handler == null) {
      await _markAsFailed(
        item,
        'No sync handler registered for ${item.entityType}',
      );
      return;
    }

    try {
      // Execute the sync operation
      await handler(item);

      // Success - remove from queue
      await _removeFromQueue(item);
    } catch (e) {
      // Failure - update retry information
      await _handleSyncFailure(item, e.toString());
    }
  }

  /// Handle sync failure by updating retry information
  Future<void> _handleSyncFailure(SyncQueueItem item, String error) async {
    if (item.hasExceededMaxRetries) {
      // Max retries exceeded - mark as permanently failed
      await _markAsFailed(item, error);
    } else {
      // Update with new retry information
      final updatedItem = item.withRetryAttempt(error);
      await _updateQueueItem(updatedItem);
    }
  }

  /// Add a new item to the sync queue
  Future<void> addToQueue(SyncQueueItem item) async {
    final companion = SyncQueueCompanion(
      id: Value(item.id),
      userId: Value(item.userId),
      operationType: Value(item.operationType.name),
      entityType: Value(item.entityType.name),
      entityId: Value(item.entityId),
      payload: Value(jsonEncode(item.payload)),
      retryCount: Value(item.retryCount),
      maxRetries: Value(item.maxRetries),
      nextRetryAt: Value(item.nextRetryAt),
      lastError: Value(item.lastError),
      createdAt: Value(item.createdAt),
      updatedAt: Value(item.updatedAt),
    );
    await _database.insertSyncQueueItem(companion);
  }

  /// Remove an item from the sync queue (after successful sync)
  Future<void> _removeFromQueue(SyncQueueItem item) async {
    await _database.deleteSyncQueueItem(item.id);
  }

  /// Update a sync queue item (after retry attempt)
  Future<void> _updateQueueItem(SyncQueueItem item) async {
    final companion = SyncQueueCompanion(
      id: Value(item.id),
      userId: Value(item.userId),
      operationType: Value(item.operationType.name),
      entityType: Value(item.entityType.name),
      entityId: Value(item.entityId),
      payload: Value(jsonEncode(item.payload)),
      retryCount: Value(item.retryCount),
      maxRetries: Value(item.maxRetries),
      nextRetryAt: Value(item.nextRetryAt),
      lastError: Value(item.lastError),
      createdAt: Value(item.createdAt),
      updatedAt: Value(item.updatedAt),
    );
    await _database.updateSyncQueueItem(companion);
  }

  /// Mark an item as permanently failed
  Future<void> _markAsFailed(SyncQueueItem item, String error) async {
    // Delete the item - failed items are removed after max retries
    // The cleanup function in the database will handle old failed items
    await _database.deleteSyncQueueItem(item.id);
  }

  /// Get pending items for a specific user
  Future<List<SyncQueueItem>> _getPendingItemsForUser(String userId) async {
    final entities = await _database.getPendingSyncQueueItems(userId);
    return entities.map(_entityToItem).toList();
  }

  /// Convert database entity to domain model
  SyncQueueItem _entityToItem(SyncQueueEntity entity) {
    return SyncQueueItem(
      id: entity.id,
      userId: entity.userId,
      operationType: SyncOperationType.values.firstWhere(
        (e) => e.name == entity.operationType,
      ),
      entityType: SyncEntityType.values.firstWhere(
        (e) => e.name == entity.entityType,
      ),
      entityId: entity.entityId,
      payload: jsonDecode(entity.payload) as Map<String, dynamic>,
      retryCount: entity.retryCount,
      maxRetries: entity.maxRetries,
      nextRetryAt: entity.nextRetryAt,
      lastError: entity.lastError,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Get count of pending sync items
  Future<int> getPendingSyncCount() async {
    return await _database.getSyncQueueCount(userId);
  }

  /// Dispose resources
  void dispose() {
    stopRetryTimer();
  }
}

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  /// Use the local version (keep our changes)
  useLocal,

  /// Use the remote version (accept server changes)
  useRemote,

  /// Last write wins (based on updated_at timestamp)
  lastWriteWins,

  /// Merge changes (custom logic per entity type)
  merge,
}

/// Result of a conflict resolution
class ConflictResolution<T> {
  final T resolvedData;
  final ConflictResolutionStrategy strategy;

  const ConflictResolution({
    required this.resolvedData,
    required this.strategy,
  });
}

/// Service for handling sync conflicts
class ConflictResolver {
  /// Resolve a conflict between local and remote data
  ConflictResolution<T> resolveConflict<T>({
    required T localData,
    required T remoteData,
    required DateTime localUpdatedAt,
    required DateTime remoteUpdatedAt,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.lastWriteWins,
  }) {
    switch (strategy) {
      case ConflictResolutionStrategy.useLocal:
        return ConflictResolution(
          resolvedData: localData,
          strategy: strategy,
        );

      case ConflictResolutionStrategy.useRemote:
        return ConflictResolution(
          resolvedData: remoteData,
          strategy: strategy,
        );

      case ConflictResolutionStrategy.lastWriteWins:
        final useLocal = localUpdatedAt.isAfter(remoteUpdatedAt);
        return ConflictResolution(
          resolvedData: useLocal ? localData : remoteData,
          strategy: strategy,
        );

      case ConflictResolutionStrategy.merge:
        // Field-level merge using EntityMerger
        if (localData is WorkoutSession && remoteData is WorkoutSession) {
          final result = EntityMerger.mergeWorkoutSession(
            localData,
            remoteData,
            MergeStrategy.fieldLevel,
          );

          return result.when(
            resolved: (merged) => ConflictResolution(
              resolvedData: merged as T,
              strategy: strategy,
            ),
            needsManualResolution: (local, remote, fields) {
              // Fallback to last write wins if manual resolution needed
              // In a real implementation, this would show a UI dialog
              final useLocal = localUpdatedAt.isAfter(remoteUpdatedAt);
              return ConflictResolution(
                resolvedData: (useLocal ? local : remote) as T,
                strategy: ConflictResolutionStrategy.lastWriteWins,
              );
            },
          );
        } else if (localData is Profile && remoteData is Profile) {
          final result = EntityMerger.mergeProfile(
            localData,
            remoteData,
            MergeStrategy.fieldLevel,
          );

          return result.when(
            resolved: (merged) => ConflictResolution(
              resolvedData: merged as T,
              strategy: strategy,
            ),
            needsManualResolution: (local, remote, fields) {
              // Fallback to last write wins if manual resolution needed
              final useLocal = localUpdatedAt.isAfter(remoteUpdatedAt);
              return ConflictResolution(
                resolvedData: (useLocal ? local : remote) as T,
                strategy: ConflictResolutionStrategy.lastWriteWins,
              );
            },
          );
        } else {
          // For unsupported types, fall back to last write wins
          final useLocal = localUpdatedAt.isAfter(remoteUpdatedAt);
          return ConflictResolution(
            resolvedData: useLocal ? localData : remoteData,
            strategy: ConflictResolutionStrategy.lastWriteWins,
          );
        }
    }
  }
}
