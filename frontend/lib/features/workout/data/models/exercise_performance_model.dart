import 'package:drift/drift.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/shared/database/app_database.dart';

/// Extension to convert Drift ExercisePerformanceEntity to domain ExercisePerformance
/// Note: Sets must be populated separately via joins
extension ExercisePerformanceModelMapper on ExercisePerformanceEntity {
  ExercisePerformance toEntity({List<WorkoutSet> sets = const []}) {
    return ExercisePerformance(
      id: id,
      workoutSessionId: workoutSessionId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      orderIndex: orderIndex,
      notes: notes,
      sets: sets,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extension to convert domain ExercisePerformance to Drift companion
extension ExercisePerformanceToDrift on ExercisePerformance {
  ExercisePerformancesCompanion toCompanion() {
    return ExercisePerformancesCompanion.insert(
      id: id,
      workoutSessionId: workoutSessionId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      orderIndex: orderIndex,
      notes: Value(notes),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Helper to convert from Supabase JSON to domain ExercisePerformance
ExercisePerformance exercisePerformanceFromJson(
  Map<String, dynamic> json, {
  List<WorkoutSet> sets = const [],
}) {
  return ExercisePerformance(
    id: json['id'] as String,
    workoutSessionId: json['workout_session_id'] as String,
    exerciseId: json['exercise_id'] as String,
    exerciseName: json['exercise_name'] as String,
    orderIndex: json['order_index'] as int,
    notes: json['notes'] as String?,
    sets: sets,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

/// Helper to convert domain ExercisePerformance to Supabase JSON
Map<String, dynamic> exercisePerformanceToJson(ExercisePerformance performance) {
  return {
    'id': performance.id,
    'workout_session_id': performance.workoutSessionId,
    'exercise_id': performance.exerciseId,
    'exercise_name': performance.exerciseName,
    'order_index': performance.orderIndex,
    'notes': performance.notes,
    'created_at': performance.createdAt.toIso8601String(),
    'updated_at': performance.updatedAt.toIso8601String(),
  };
}
