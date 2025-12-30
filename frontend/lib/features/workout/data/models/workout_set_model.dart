import 'package:drift/drift.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/shared/database/app_database.dart';

/// Extension to convert Drift SetEntity to domain WorkoutSet
extension WorkoutSetModelMapper on SetEntity {
  WorkoutSet toEntity() {
    return WorkoutSet(
      id: id,
      exercisePerformanceId: exercisePerformanceId,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      isWarmup: isWarmup,
      isDropset: isDropset,
      rpe: rpe,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extension to convert domain WorkoutSet to Drift companion
extension WorkoutSetToDrift on WorkoutSet {
  SetsCompanion toCompanion() {
    return SetsCompanion.insert(
      id: id,
      exercisePerformanceId: exercisePerformanceId,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      isWarmup: Value(isWarmup),
      isDropset: Value(isDropset),
      rpe: Value(rpe),
      notes: Value(notes),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Helper to convert from Supabase JSON to domain WorkoutSet
WorkoutSet workoutSetFromJson(Map<String, dynamic> json) {
  return WorkoutSet(
    id: json['id'] as String,
    exercisePerformanceId: json['exercise_performance_id'] as String,
    setNumber: json['set_number'] as int,
    reps: json['reps'] as int,
    weightKg: (json['weight_kg'] as num).toDouble(),
    isWarmup: json['is_warmup'] as bool? ?? false,
    isDropset: json['is_dropset'] as bool? ?? false,
    rpe: json['rpe'] != null ? (json['rpe'] as num).toDouble() : null,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

/// Helper to convert domain WorkoutSet to Supabase JSON
Map<String, dynamic> workoutSetToJson(WorkoutSet set) {
  return {
    'id': set.id,
    'exercise_performance_id': set.exercisePerformanceId,
    'set_number': set.setNumber,
    'reps': set.reps,
    'weight_kg': set.weightKg,
    'is_warmup': set.isWarmup,
    'is_dropset': set.isDropset,
    'rpe': set.rpe,
    'notes': set.notes,
    'created_at': set.createdAt.toIso8601String(),
    'updated_at': set.updatedAt.toIso8601String(),
  };
}
