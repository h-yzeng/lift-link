import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:liftlink/shared/database/tables/exercises_table.dart';
import 'package:liftlink/shared/database/tables/friendships_table.dart';
import 'package:liftlink/shared/database/tables/profiles_table.dart';
import 'package:liftlink/shared/database/tables/sets_table.dart';
import 'package:liftlink/shared/database/tables/sync_queue_table.dart';
import 'package:liftlink/shared/database/tables/weight_logs_table.dart';
import 'package:liftlink/shared/database/tables/workout_sessions_table.dart';
import 'package:liftlink/shared/database/tables/workout_templates_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Profiles,
    Exercises,
    WorkoutSessions,
    ExercisePerformances,
    Sets,
    Friendships,
    WorkoutTemplates,
    SyncQueue,
    WeightLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // For testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Migration from v1 to v2: Add exercise_name column if it doesn't exist
          if (from < 2) {
            // Delete and recreate tables to ensure clean schema
            // This is acceptable during development before production
            await m.deleteTable(exercisePerformances.actualTableName);
            await m.deleteTable(sets.actualTableName);
            await m.deleteTable(workoutSessions.actualTableName);

            await m.createTable(workoutSessions);
            await m.createTable(exercisePerformances);
            await m.createTable(sets);

            // Clear and resync exercises to remove duplicates
            await delete(exercises).go();
          }

          // Migration from v2 to v3: Add preferred_units column
          if (from < 3) {
            await customStatement(
              'ALTER TABLE profiles ADD COLUMN preferred_units TEXT NOT NULL DEFAULT "imperial"',
            );
          }

          // Migration from v3 to v4: Make username nullable
          if (from < 4) {
            // SQLite doesn't support ALTER COLUMN, need to recreate table
            await customStatement(
              'CREATE TABLE profiles_new ('
              'id TEXT PRIMARY KEY, '
              'username TEXT, '
              'display_name TEXT, '
              'avatar_url TEXT, '
              'bio TEXT, '
              'preferred_units TEXT NOT NULL DEFAULT "imperial", '
              'created_at INTEGER NOT NULL, '
              'updated_at INTEGER NOT NULL, '
              'synced_at INTEGER'
              ')',
            );

            await customStatement(
              'INSERT INTO profiles_new SELECT * FROM profiles',
            );

            await customStatement('DROP TABLE profiles');
            await customStatement('ALTER TABLE profiles_new RENAME TO profiles');
          }

          // Migration from v4 to v5: Add nickname columns to friendships
          if (from < 5) {
            await customStatement(
              'ALTER TABLE friendships ADD COLUMN requester_nickname TEXT',
            );
            await customStatement(
              'ALTER TABLE friendships ADD COLUMN addressee_nickname TEXT',
            );
          }

          // Migration from v5 to v6: Add workout_templates table
          if (from < 6) {
            await m.createTable(workoutTemplates);
          }

          // Migration from v6 to v7: Add sync_queue table
          if (from < 7) {
            // Check if table already exists before creating
            final result = await customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_queue'",
            ).getSingleOrNull();

            if (result == null) {
              await m.createTable(syncQueue);
            }
          }

          // Migration from v7 to v8: Add weight_logs table
          if (from < 8) {
            await m.createTable(weightLogs);
          }

          // Migration from v8 to v9: Add RIR column to sets table
          if (from < 9) {
            await customStatement(
              'ALTER TABLE sets ADD COLUMN rir INTEGER CHECK (rir IS NULL OR (rir >= 0 AND rir <= 10))',
            );
          }
        },
        beforeOpen: (details) async {
          // Enable WAL mode for better concurrency
          await customStatement('PRAGMA journal_mode = WAL');
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
          // Set a reasonable busy timeout (10 seconds)
          await customStatement('PRAGMA busy_timeout = 10000');
        },
      );

  // ============================================================================
  // PROFILE QUERIES
  // ============================================================================

  Future<ProfileEntity?> getProfile(String id) =>
      (select(profiles)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<int> upsertProfile(ProfilesCompanion profile) =>
      into(profiles).insertOnConflictUpdate(profile);

  Stream<ProfileEntity?> watchProfile(String id) =>
      (select(profiles)..where((p) => p.id.equals(id))).watchSingleOrNull();

  // ============================================================================
  // EXERCISE QUERIES
  // ============================================================================

  Future<List<ExerciseEntity>> getAllExercises() => select(exercises).get();

  Future<List<ExerciseEntity>> getExercisesByMuscleGroup(String muscleGroup) =>
      (select(exercises)..where((e) => e.muscleGroup.equals(muscleGroup)))
          .get();

  Future<ExerciseEntity?> getExerciseById(String id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> insertExercise(ExercisesCompanion exercise) =>
      into(exercises).insert(exercise);

  Stream<List<ExerciseEntity>> watchAllExercises() => select(exercises).watch();

  // ============================================================================
  // WORKOUT SESSION QUERIES
  // ============================================================================

  Future<List<WorkoutSessionEntity>> getWorkoutSessions(String userId) =>
      (select(workoutSessions)
            ..where((w) => w.userId.equals(userId))
            ..orderBy([(w) => OrderingTerm.desc(w.startedAt)]))
          .get();

  Future<WorkoutSessionEntity?> getWorkoutSessionById(String id) =>
      (select(workoutSessions)..where((w) => w.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertWorkoutSession(WorkoutSessionsCompanion session) =>
      into(workoutSessions).insert(session);

  Future<bool> updateWorkoutSession(WorkoutSessionsCompanion session) =>
      update(workoutSessions).replace(session);

  Future<int> deleteWorkoutSession(String id) =>
      (delete(workoutSessions)..where((w) => w.id.equals(id))).go();

  Stream<List<WorkoutSessionEntity>> watchWorkoutSessions(String userId) =>
      (select(workoutSessions)
            ..where((w) => w.userId.equals(userId))
            ..orderBy([(w) => OrderingTerm.desc(w.startedAt)]))
          .watch();

  Future<List<WorkoutSessionEntity>> getPendingSyncWorkouts() =>
      (select(workoutSessions)..where((w) => w.isPendingSync.equals(true)))
          .get();

  Future<void> markWorkoutSynced(String id) async {
    await (update(workoutSessions)..where((w) => w.id.equals(id))).write(
      WorkoutSessionsCompanion(
        syncedAt: Value(DateTime.now()),
        isPendingSync: const Value(false),
      ),
    );
  }

  // ============================================================================
  // EXERCISE PERFORMANCE QUERIES
  // ============================================================================

  Future<List<ExercisePerformanceEntity>> getExercisePerformances(
    String workoutSessionId,
  ) =>
      (select(exercisePerformances)
            ..where((e) => e.workoutSessionId.equals(workoutSessionId))
            ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
          .get();

  Future<int> insertExercisePerformance(
    ExercisePerformancesCompanion performance,
  ) =>
      into(exercisePerformances).insert(performance);

  Future<int> deleteExercisePerformance(String id) =>
      (delete(exercisePerformances)..where((e) => e.id.equals(id))).go();

  // ============================================================================
  // SET QUERIES
  // ============================================================================

  Future<List<SetEntity>> getSets(String exercisePerformanceId) => (select(sets)
        ..where((s) => s.exercisePerformanceId.equals(exercisePerformanceId))
        ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
      .get();

  Future<int> insertSet(SetsCompanion set) => into(sets).insert(set);

  Future<bool> updateSet(SetsCompanion set) => update(sets).replace(set);

  Future<int> deleteSet(String id) =>
      (delete(sets)..where((s) => s.id.equals(id))).go();

  // ============================================================================
  // FRIENDSHIP QUERIES
  // ============================================================================

  Future<List<FriendshipEntity>> getFriendships(String userId) =>
      (select(friendships)
            ..where(
              (f) =>
                  f.requesterId.equals(userId) | f.addresseeId.equals(userId),
            ))
          .get();

  Future<List<FriendshipEntity>> getAcceptedFriends(String userId) =>
      (select(friendships)
            ..where(
              (f) =>
                  f.status.equals('accepted') &
                  (f.requesterId.equals(userId) | f.addresseeId.equals(userId)),
            ))
          .get();

  Future<List<FriendshipEntity>> getPendingFriendRequests(String userId) =>
      (select(friendships)
            ..where(
              (f) => f.status.equals('pending') & f.addresseeId.equals(userId),
            ))
          .get();

  Future<int> insertFriendship(FriendshipsCompanion friendship) =>
      into(friendships).insert(friendship);

  Future<void> updateFriendshipStatus(String id, String status) async {
    await (update(friendships)..where((f) => f.id.equals(id))).write(
      FriendshipsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteFriendship(String id) =>
      (delete(friendships)..where((f) => f.id.equals(id))).go();

  Stream<List<FriendshipEntity>> watchFriendships(String userId) =>
      (select(friendships)
            ..where(
              (f) =>
                  f.requesterId.equals(userId) | f.addresseeId.equals(userId),
            ))
          .watch();

  // ============================================================================
  // SYNC QUEUE QUERIES
  // ============================================================================

  Future<int> insertSyncQueueItem(SyncQueueCompanion item) =>
      into(syncQueue).insert(item);

  Future<bool> updateSyncQueueItem(SyncQueueCompanion item) =>
      update(syncQueue).replace(item);

  Future<int> deleteSyncQueueItem(String id) =>
      (delete(syncQueue)..where((s) => s.id.equals(id))).go();

  Future<List<SyncQueueEntity>> getPendingSyncQueueItems(String userId) async {
    final now = DateTime.now();
    return (select(syncQueue)
          ..where(
            (s) =>
                s.userId.equals(userId) &
                s.retryCount.isSmallerThan(s.maxRetries) &
                (s.nextRetryAt.isNull() | s.nextRetryAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .get();
  }

  Future<SyncQueueEntity?> getSyncQueueItemById(String id) =>
      (select(syncQueue)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<int> getSyncQueueCount(String userId) async {
    final query = selectOnly(syncQueue)
      ..addColumns([syncQueue.id.count()])
      ..where(
        syncQueue.userId.equals(userId) &
            syncQueue.retryCount.isSmallerThan(syncQueue.maxRetries),
      );
    final result = await query.getSingle();
    return result.read(syncQueue.id.count()) ?? 0;
  }

  Future<void> clearOldFailedSyncItems(String userId) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    await (delete(syncQueue)
          ..where(
            (s) =>
                s.userId.equals(userId) &
                s.retryCount.isBiggerOrEqual(s.maxRetries) &
                s.updatedAt.isSmallerThanValue(sevenDaysAgo),
          ))
        .go();
  }

  // ============================================================================
  // WEIGHT LOGS QUERIES
  // ============================================================================

  Future<List<WeightLogEntity>> getWeightLogs(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    var query = select(weightLogs)
      ..where((w) => w.userId.equals(userId))
      ..orderBy([(w) => OrderingTerm.desc(w.loggedAt)]);

    if (startDate != null) {
      query = query
        ..where((w) => w.loggedAt.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query = query..where((w) => w.loggedAt.isSmallerOrEqualValue(endDate));
    }

    if (limit != null) {
      query = query..limit(limit);
    }

    return query.get();
  }

  Future<WeightLogEntity?> getLatestWeightLog(String userId) async {
    return (select(weightLogs)
          ..where((w) => w.userId.equals(userId))
          ..orderBy([(w) => OrderingTerm.desc(w.loggedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<WeightLogEntity?> getWeightLogById(String id) =>
      (select(weightLogs)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<int> insertWeightLog(WeightLogsCompanion weightLog) =>
      into(weightLogs).insert(weightLog);

  Future<bool> updateWeightLog(WeightLogsCompanion weightLog) =>
      update(weightLogs).replace(weightLog);

  Future<int> deleteWeightLog(String id) =>
      (delete(weightLogs)..where((w) => w.id.equals(id))).go();

  Stream<List<WeightLogEntity>> watchWeightLogs(
    String userId, {
    int? limit,
  }) {
    var query = select(weightLogs)
      ..where((w) => w.userId.equals(userId))
      ..orderBy([(w) => OrderingTerm.desc(w.loggedAt)]);

    if (limit != null) {
      query = query..limit(limit);
    }

    return query.watch();
  }

  Future<List<WeightLogEntity>> getPendingSyncWeightLogs() =>
      (select(weightLogs)..where((w) => w.isPendingSync.equals(true))).get();

  Future<void> markWeightLogSynced(String id) async {
    await (update(weightLogs)..where((w) => w.id.equals(id))).write(
      WeightLogsCompanion(
        syncedAt: Value(DateTime.now()),
        isPendingSync: const Value(false),
      ),
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Clear all data from the database
  Future<void> clearAllData() async {
    await delete(sets).go();
    await delete(exercisePerformances).go();
    await delete(workoutSessions).go();
    await delete(friendships).go();
    await delete(profiles).go();
    // Don't delete exercises (keep system exercises)
    await (delete(exercises)..where((e) => e.isCustom.equals(true))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'liftlink.db'));
    return NativeDatabase.createInBackground(file);
  });
}
