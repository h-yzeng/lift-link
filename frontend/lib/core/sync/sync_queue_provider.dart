import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/core/sync/sync_queue_service.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/shared/database/database_provider.dart';

part 'sync_queue_provider.g.dart';

@riverpod
Future<String?> currentUserId(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user?.id;
}

@riverpod
Future<SyncQueueService> syncQueueService(Ref ref) async {
  final networkInfo = ref.watch(networkInfoProvider);
  final database = ref.watch(databaseProvider);
  final userId = await ref.watch(currentUserIdProvider.future);

  if (userId == null) {
    throw Exception('User must be authenticated to use sync queue');
  }

  final service = SyncQueueService(networkInfo, database, userId);

  // Start retry timer when service is created
  service.startRetryTimer();

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}

@riverpod
Future<int> pendingSyncCount(Ref ref) async {
  final service = await ref.watch(syncQueueServiceProvider.future);
  return await service.getPendingSyncCount();
}
