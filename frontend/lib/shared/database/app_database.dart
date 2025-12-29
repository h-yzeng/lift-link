import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/exercises_table.dart';
import 'tables/friendships_table.dart';
import 'tables/profiles_table.dart';
import 'tables/sets_table.dart';
import 'tables/workout_sessions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Profiles,
    Exercises,
    WorkoutSessions,
    ExercisePerformances,
    Sets,
    Friendships,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // For testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle future migrations here
          // Example:
          // if (from < 2) {
          //   await m.addColumn(profiles, profiles.newColumn);
          // }
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
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
      (select(exercises)..where((e) => e.muscleGroup.equals(muscleGroup))).get();

  Future<ExerciseEntity?> getExerciseById(String id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> insertExercise(ExercisesCompanion exercise) =>
      into(exercises).insert(exercise);

  Stream<List<ExerciseEntity>> watchAllExercises() =>
      select(exercises).watch();

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

  Future<List<SetEntity>> getSets(String exercisePerformanceId) =>
      (select(sets)
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
              (f) =>
                  f.status.equals('pending') & f.addresseeId.equals(userId),
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
