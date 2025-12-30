import 'package:drift/drift.dart';
import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/data/models/exercise_model.dart';
import 'package:liftlink/shared/database/app_database.dart';

/// Local data source for exercises using Drift
abstract class ExerciseLocalDataSource {
  /// Get all exercises
  Future<List<Exercise>> getAllExercises({String? userId});

  /// Get exercise by ID
  Future<Exercise> getExerciseById(String id);

  /// Search exercises by name
  Future<List<Exercise>> searchExercises({
    required String query,
    String? userId,
  });

  /// Filter exercises by muscle group
  Future<List<Exercise>> getExercisesByMuscleGroup({
    required String muscleGroup,
    String? userId,
  });

  /// Filter exercises by equipment type
  Future<List<Exercise>> getExercisesByEquipment({
    required String equipmentType,
    String? userId,
  });

  /// Filter exercises with multiple criteria
  Future<List<Exercise>> filterExercises({
    String? muscleGroup,
    String? equipmentType,
    bool? customOnly,
    String? userId,
  });

  /// Insert or update exercise
  Future<void> upsertExercise(Exercise exercise);

  /// Insert multiple exercises
  Future<void> upsertExercises(List<Exercise> exercises);

  /// Delete exercise
  Future<void> deleteExercise(String id);

  /// Clear all exercises (for resync)
  Future<void> clearExercises();
}

class ExerciseLocalDataSourceImpl implements ExerciseLocalDataSource {
  final AppDatabase database;

  ExerciseLocalDataSourceImpl({required this.database});

  @override
  Future<List<Exercise>> getAllExercises({String? userId}) async {
    try {
      final query = database.select(database.exercises);

      // Get system exercises + user's custom exercises
      if (userId != null) {
        query.where(
          (ex) => ex.isCustom.equals(false) | ex.createdBy.equals(userId),
        );
      } else {
        // Only system exercises if no user
        query.where((ex) => ex.isCustom.equals(false));
      }

      query.orderBy([
        (ex) => OrderingTerm(expression: ex.muscleGroup),
        (ex) => OrderingTerm(expression: ex.name),
      ]);

      final results = await query.get();
      return results.map((e) => e.toEntity()).toList();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<Exercise> getExerciseById(String id) async {
    try {
      final query = database.select(database.exercises)
        ..where((ex) => ex.id.equals(id));

      final result = await query.getSingleOrNull();
      if (result == null) {
        throw const CacheException(message: 'Exercise not found');
      }

      return result.toEntity();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<Exercise>> searchExercises({
    required String query,
    String? userId,
  }) async {
    try {
      final selectQuery = database.select(database.exercises);

      // Search in name or description
      selectQuery.where(
        (ex) =>
            ex.name.lower().like('%${query.toLowerCase()}%') |
            ex.description.lower().like('%${query.toLowerCase()}%'),
      );

      // Filter by user access
      if (userId != null) {
        selectQuery.where(
          (ex) => ex.isCustom.equals(false) | ex.createdBy.equals(userId),
        );
      } else {
        selectQuery.where((ex) => ex.isCustom.equals(false));
      }

      selectQuery.orderBy([
        (ex) => OrderingTerm(expression: ex.name),
      ]);

      final results = await selectQuery.get();
      return results.map((e) => e.toEntity()).toList();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<Exercise>> getExercisesByMuscleGroup({
    required String muscleGroup,
    String? userId,
  }) async {
    try {
      final query = database.select(database.exercises);

      query.where((ex) => ex.muscleGroup.equals(muscleGroup));

      if (userId != null) {
        query.where(
          (ex) => ex.isCustom.equals(false) | ex.createdBy.equals(userId),
        );
      } else {
        query.where((ex) => ex.isCustom.equals(false));
      }

      query.orderBy([
        (ex) => OrderingTerm(expression: ex.name),
      ]);

      final results = await query.get();
      return results.map((e) => e.toEntity()).toList();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<Exercise>> getExercisesByEquipment({
    required String equipmentType,
    String? userId,
  }) async {
    try {
      final query = database.select(database.exercises);

      query.where((ex) => ex.equipmentType.equals(equipmentType));

      if (userId != null) {
        query.where(
          (ex) => ex.isCustom.equals(false) | ex.createdBy.equals(userId),
        );
      } else {
        query.where((ex) => ex.isCustom.equals(false));
      }

      query.orderBy([
        (ex) => OrderingTerm(expression: ex.name),
      ]);

      final results = await query.get();
      return results.map((e) => e.toEntity()).toList();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<Exercise>> filterExercises({
    String? muscleGroup,
    String? equipmentType,
    bool? customOnly,
    String? userId,
  }) async {
    try {
      final query = database.select(database.exercises);

      // Apply filters
      if (muscleGroup != null) {
        query.where((ex) => ex.muscleGroup.equals(muscleGroup));
      }

      if (equipmentType != null) {
        query.where((ex) => ex.equipmentType.equals(equipmentType));
      }

      if (customOnly == true && userId != null) {
        query.where(
          (ex) => ex.isCustom.equals(true) & ex.createdBy.equals(userId),
        );
      } else if (userId != null) {
        query.where(
          (ex) => ex.isCustom.equals(false) | ex.createdBy.equals(userId),
        );
      } else {
        query.where((ex) => ex.isCustom.equals(false));
      }

      query.orderBy([
        (ex) => OrderingTerm(expression: ex.muscleGroup),
        (ex) => OrderingTerm(expression: ex.name),
      ]);

      final results = await query.get();
      return results.map((e) => e.toEntity()).toList();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> upsertExercise(Exercise exercise) async {
    try {
      await database.into(database.exercises).insertOnConflictUpdate(
            exercise.toCompanion(),
          );
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> upsertExercises(List<Exercise> exercises) async {
    try {
      await database.batch((batch) {
        batch.insertAllOnConflictUpdate(
          database.exercises,
          exercises.map((e) => e.toCompanion()).toList(),
        );
      });
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> deleteExercise(String id) async {
    try {
      await (database.delete(database.exercises)
            ..where((ex) => ex.id.equals(id)))
          .go();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> clearExercises() async {
    try {
      await database.delete(database.exercises).go();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
