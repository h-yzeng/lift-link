import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/bodyweight/domain/entities/weight_log.dart';
import 'package:liftlink/shared/database/app_database.dart';
import 'package:liftlink/shared/database/database_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

part 'weight_log_providers.g.dart';

@riverpod
Stream<List<WeightLog>> weightLogs(Ref ref, {int? limit}) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield [];
    return;
  }

  final database = ref.watch(databaseProvider);
  await for (final logs in database.watchWeightLogs(user.id, limit: limit)) {
    yield logs.map((entity) => _entityToWeightLog(entity)).toList();
  }
}

@riverpod
Future<WeightLog?> latestWeightLog(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;

  final database = ref.watch(databaseProvider);
  final entity = await database.getLatestWeightLog(user.id);

  return entity != null ? _entityToWeightLog(entity) : null;
}

@riverpod
class WeightLogNotifier extends _$WeightLogNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> logWeight({
    required double weight,
    required String unit,
    String? notes,
    DateTime? loggedAt,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User not authenticated');

      final database = ref.read(databaseProvider);
      final weightLog = WeightLogsCompanion(
        id: Value(const Uuid().v4()),
        userId: Value(user.id),
        weight: Value(weight),
        unit: Value(unit),
        notes: Value(notes),
        loggedAt: Value(loggedAt ?? DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(true),
      );

      await database.insertWeightLog(weightLog);

      // Invalidate the weight logs provider to refresh the list
      ref.invalidate(weightLogsProvider);
      ref.invalidate(latestWeightLogProvider);
    });
  }

  Future<void> deleteWeight(String id) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final database = ref.read(databaseProvider);
      await database.deleteWeightLog(id);

      // Invalidate to refresh
      ref.invalidate(weightLogsProvider);
      ref.invalidate(latestWeightLogProvider);
    });
  }

  Future<void> updateWeight({
    required String id,
    required double weight,
    required String unit,
    String? notes,
    required DateTime loggedAt,
    required DateTime createdAt,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User not authenticated');

      final database = ref.read(databaseProvider);
      final weightLog = WeightLogsCompanion(
        id: Value(id),
        userId: Value(user.id),
        weight: Value(weight),
        unit: Value(unit),
        notes: Value(notes),
        loggedAt: Value(loggedAt),
        createdAt: Value(createdAt),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(true),
      );

      await database.updateWeightLog(weightLog);

      // Invalidate to refresh
      ref.invalidate(weightLogsProvider);
      ref.invalidate(latestWeightLogProvider);
    });
  }
}

WeightLog _entityToWeightLog(dynamic entity) {
  return WeightLog(
    id: entity.id as String,
    userId: entity.userId as String,
    weight: entity.weight as double,
    unit: entity.unit as String,
    notes: entity.notes as String?,
    loggedAt: entity.loggedAt as DateTime,
    createdAt: entity.createdAt as DateTime,
    updatedAt: entity.updatedAt as DateTime,
  );
}
