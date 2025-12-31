import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';

/// Use case to export workout data.
class ExportWorkoutData {
  final WorkoutRepository _repository;

  ExportWorkoutData(this._repository);

  /// Export workout data as JSON string.
  Future<Either<Failure, String>> call({
    required String userId,
    ExportFormat format = ExportFormat.json,
  }) async {
    final result = await _repository.getWorkoutHistory(userId: userId);

    return result.fold(
      (failure) => Left(failure),
      (workouts) {
        switch (format) {
          case ExportFormat.json:
            return Right(_toJson(workouts));
          case ExportFormat.csv:
            return Right(_toCsv(workouts));
        }
      },
    );
  }

  String _toJson(List<WorkoutSession> workouts) {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'totalWorkouts': workouts.length,
      'workouts': workouts.map((w) => _workoutToMap(w)).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Map<String, dynamic> _workoutToMap(WorkoutSession workout) {
    return {
      'id': workout.id,
      'title': workout.title,
      'startedAt': workout.startedAt.toIso8601String(),
      'completedAt': workout.completedAt?.toIso8601String(),
      'duration': workout.formattedDuration,
      'exerciseCount': workout.exerciseCount,
      'totalSets': workout.totalSets,
      'totalVolume': workout.totalVolume,
      'exercises': workout.exercises.map((e) => {
        'exerciseId': e.exerciseId,
        'exerciseName': e.exerciseName,
        'notes': e.notes,
        'sets': e.sets.map((s) => {
          'setNumber': s.setNumber,
          'reps': s.reps,
          'weightKg': s.weightKg,
          'isWarmup': s.isWarmup,
          'rpe': s.rpe,
          'oneRepMax': s.calculated1RM,
        },).toList(),
      },).toList(),
    };
  }

  String _toCsv(List<WorkoutSession> workouts) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Workout Date,Workout Title,Exercise,Set,Reps,Weight (kg),Warmup,RPE,1RM');

    for (final workout in workouts) {
      final workoutDate = workout.startedAt.toIso8601String().split('T').first;

      for (final exercise in workout.exercises) {
        for (final set in exercise.sets) {
          buffer.writeln(
            '$workoutDate,'
            '"${workout.title}",'
            '"${exercise.exerciseName}",'
            '${set.setNumber},'
            '${set.reps},'
            '${set.weightKg},'
            '${set.isWarmup},'
            '${set.rpe ?? ""},'
            '${set.calculated1RM ?? ""}',
          );
        }
      }
    }

    return buffer.toString();
  }
}

/// Supported export formats.
enum ExportFormat {
  json,
  csv,
}
