import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/features/workout/domain/repositories/exercise_repository.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Sync status for tracking synchronization state.
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

/// Result of a sync operation.
class SyncResult {
  final SyncStatus status;
  final String? message;
  final int itemsSynced;
  final DateTime timestamp;

  SyncResult({
    required this.status,
    this.message,
    this.itemsSynced = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SyncResult.success({int itemsSynced = 0}) => SyncResult(
        status: SyncStatus.success,
        itemsSynced: itemsSynced,
      );

  factory SyncResult.error(String message) => SyncResult(
        status: SyncStatus.error,
        message: message,
      );

  factory SyncResult.offline() => SyncResult(
        status: SyncStatus.offline,
        message: 'No internet connection',
      );

  factory SyncResult.idle() => SyncResult(status: SyncStatus.idle);
}

/// Service for synchronizing local data with Supabase.
///
/// This service handles:
/// - Background sync when app is active
/// - Sync on app resume
/// - Manual sync triggers
/// - Sync status tracking
class SyncService {
  final NetworkInfo _networkInfo;
  final ExerciseRepository _exerciseRepository;
  final WorkoutRepository _workoutRepository;

  Timer? _periodicSyncTimer;
  final _syncStatusController = StreamController<SyncResult>.broadcast();
  SyncResult _lastSyncResult = SyncResult.idle();
  bool _isSyncing = false;

  SyncService({
    required NetworkInfo networkInfo,
    required ExerciseRepository exerciseRepository,
    required WorkoutRepository workoutRepository,
  })  : _networkInfo = networkInfo,
        _exerciseRepository = exerciseRepository,
        _workoutRepository = workoutRepository;

  /// Stream of sync status updates.
  Stream<SyncResult> get syncStatusStream => _syncStatusController.stream;

  /// The last sync result.
  SyncResult get lastSyncResult => _lastSyncResult;

  /// Whether a sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Start periodic background sync.
  ///
  /// [interval] - How often to sync (default: 5 minutes)
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(interval, (_) => syncAll());

    // Also run an initial sync
    syncAll();
  }

  /// Stop periodic background sync.
  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Perform a full sync of all data.
  ///
  /// Returns a [SyncResult] with the outcome.
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return _lastSyncResult;
    }

    _isSyncing = true;
    _emitStatus(SyncResult(status: SyncStatus.syncing));

    try {
      // Check network connectivity
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        final result = SyncResult.offline();
        _emitStatus(result);
        return result;
      }

      int totalItemsSynced = 0;

      // Sync exercises
      try {
        final exerciseResult = await _exerciseRepository.syncExercises();
        exerciseResult.fold(
          (failure) => debugPrint('Exercise sync failed: ${failure.message}'),
          (_) => totalItemsSynced++,
        );
      } catch (e) {
        debugPrint('Exercise sync error: $e');
      }

      // Sync workouts
      try {
        final workoutResult = await _workoutRepository.syncWorkouts();
        workoutResult.fold(
          (failure) => debugPrint('Workout sync failed: ${failure.message}'),
          (_) => totalItemsSynced++,
        );
      } catch (e) {
        debugPrint('Workout sync error: $e');
      }

      final result = SyncResult.success(itemsSynced: totalItemsSynced);
      _emitStatus(result);
      return result;
    } catch (e) {
      final result = SyncResult.error(e.toString());
      _emitStatus(result);
      return result;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync only exercises.
  Future<SyncResult> syncExercises() async {
    if (_isSyncing) return _lastSyncResult;

    _isSyncing = true;
    _emitStatus(SyncResult(status: SyncStatus.syncing));

    try {
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        final result = SyncResult.offline();
        _emitStatus(result);
        return result;
      }

      final exerciseResult = await _exerciseRepository.syncExercises();

      return exerciseResult.fold(
        (failure) {
          final result = SyncResult.error(failure.message ?? 'Sync failed');
          _emitStatus(result);
          return result;
        },
        (_) {
          final result = SyncResult.success(itemsSynced: 1);
          _emitStatus(result);
          return result;
        },
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync only workouts.
  Future<SyncResult> syncWorkouts() async {
    if (_isSyncing) return _lastSyncResult;

    _isSyncing = true;
    _emitStatus(SyncResult(status: SyncStatus.syncing));

    try {
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        final result = SyncResult.offline();
        _emitStatus(result);
        return result;
      }

      final workoutResult = await _workoutRepository.syncWorkouts();

      return workoutResult.fold(
        (failure) {
          final result = SyncResult.error(failure.message ?? 'Sync failed');
          _emitStatus(result);
          return result;
        },
        (_) {
          final result = SyncResult.success(itemsSynced: 1);
          _emitStatus(result);
          return result;
        },
      );
    } finally {
      _isSyncing = false;
    }
  }

  void _emitStatus(SyncResult result) {
    _lastSyncResult = result;
    _syncStatusController.add(result);
  }

  /// Clean up resources.
  void dispose() {
    _periodicSyncTimer?.cancel();
    _syncStatusController.close();
  }
}
