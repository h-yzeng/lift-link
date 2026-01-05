import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/core/sync/sync_service.dart';
import 'package:liftlink/features/workout/presentation/providers/exercise_providers.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';

/// Provider for the network info.
final networkInfoSyncProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(connectivity: Connectivity());
});

/// Provider for the sync service.
final syncServiceProvider = Provider<SyncService>((ref) {
  final networkInfo = ref.watch(networkInfoSyncProvider);
  final exerciseRepository = ref.watch(exerciseRepositoryProvider);
  final workoutRepository = ref.watch(workoutRepositoryProvider);

  final service = SyncService(
    networkInfo: networkInfo,
    exerciseRepository: exerciseRepository,
    workoutRepository: workoutRepository,
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for the sync status stream.
final syncStatusStreamProvider = StreamProvider<SyncResult>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStatusStream;
});

/// Provider for the last sync result.
final lastSyncResultProvider = Provider<SyncResult>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.lastSyncResult;
});

/// Provider for whether a sync is in progress.
final isSyncingProvider = Provider<bool>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.isSyncing;
});
