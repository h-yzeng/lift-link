import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:liftlink/features/workout/domain/entities/workout_template.dart'
    as domain;
import 'package:liftlink/shared/database/app_database.dart' as db;

/// Local data source for workout templates using Drift.
class TemplateLocalDataSource {
  final db.AppDatabase _database;

  TemplateLocalDataSource(this._database);

  /// Get all templates for a user.
  Future<List<domain.WorkoutTemplate>> getTemplates(String userId) async {
    final query = _database.select(_database.workoutTemplates)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    final entities = await query.get();
    return entities.map(_entityToTemplate).toList();
  }

  /// Get a single template by ID.
  Future<domain.WorkoutTemplate?> getTemplateById(String id) async {
    final query = _database.select(_database.workoutTemplates)
      ..where((t) => t.id.equals(id));

    final entity = await query.getSingleOrNull();
    return entity != null ? _entityToTemplate(entity) : null;
  }

  /// Insert a new template.
  Future<void> insertTemplate(domain.WorkoutTemplate template) async {
    final companion = db.WorkoutTemplatesCompanion.insert(
      id: template.id,
      userId: template.userId,
      name: template.name,
      description: Value(template.description),
      exercisesJson: jsonEncode(template.exercises.map((e) => e.toJson()).toList()),
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
    );

    await _database.into(_database.workoutTemplates).insert(companion);
  }

  /// Update an existing template.
  Future<void> updateTemplate(domain.WorkoutTemplate template) async {
    final companion = db.WorkoutTemplatesCompanion(
      id: Value(template.id),
      userId: Value(template.userId),
      name: Value(template.name),
      description: Value(template.description),
      exercisesJson: Value(jsonEncode(template.exercises.map((e) => e.toJson()).toList())),
      updatedAt: Value(template.updatedAt),
    );

    await (_database.update(_database.workoutTemplates)
          ..where((t) => t.id.equals(template.id)))
        .write(companion);
  }

  /// Delete a template.
  Future<void> deleteTemplate(String id) async {
    await (_database.delete(_database.workoutTemplates)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Convert database entity to domain entity.
  domain.WorkoutTemplate _entityToTemplate(db.WorkoutTemplate entity) {
    final exercisesList = jsonDecode(entity.exercisesJson) as List<dynamic>;
    final exercises = exercisesList
        .map((e) => domain.TemplateExercise.fromJson(e as Map<String, dynamic>))
        .toList();

    return domain.WorkoutTemplate(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      description: entity.description,
      exercises: exercises,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
