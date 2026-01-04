import 'package:liftlink/features/workout/domain/entities/workout_session.dart';

/// Service providing intelligent workout recommendations based on history.
///
/// Analyzes workout patterns to suggest:
/// - Next exercises to perform
/// - Optimal workout timing
/// - Exercise variations
/// - Volume adjustments
/// - Recovery-optimized scheduling
///
/// Example usage:
/// ```dart
/// final service = SmartWorkoutRecommendationService();
/// final recommendations = service.generateRecommendations(workoutHistory);
/// ```
class SmartWorkoutRecommendationService {
  /// Generates comprehensive workout recommendations.
  WorkoutRecommendations generateRecommendations(
    List<WorkoutSession> recentWorkouts,
  ) {
    if (recentWorkouts.isEmpty) {
      return WorkoutRecommendations(
        suggestedExercises: _getDefaultExercises(),
        optimalRestDays: 1,
        suggestedDuration: 60,
        volumeAdjustment: VolumeAdjustment.maintain,
        reasoning:
            'Start with fundamental compound exercises to build a strong foundation.',
      );
    }

    final analysis = _analyzeWorkoutPatterns(recentWorkouts);

    return WorkoutRecommendations(
      suggestedExercises: _suggestNextExercises(analysis),
      optimalRestDays: _calculateOptimalRestDays(analysis),
      suggestedDuration: _suggestWorkoutDuration(analysis),
      volumeAdjustment: _suggestVolumeAdjustment(analysis),
      reasoning: _generateReasoning(analysis),
      muscleGroupSuggestions: _suggestMuscleGroups(analysis),
    );
  }

  /// Suggests the next exercises to perform based on training balance.
  List<ExerciseSuggestion> suggestNextExercises(
    List<WorkoutSession> recentWorkouts,
    int count,
  ) {
    final analysis = _analyzeWorkoutPatterns(recentWorkouts);
    return _suggestNextExercises(analysis).take(count).toList();
  }

  /// Recommends optimal workout timing based on past performance.
  TimeRecommendation suggestWorkoutTiming(
    List<WorkoutSession> recentWorkouts,
  ) {
    if (recentWorkouts.isEmpty) {
      return TimeRecommendation(
        recommendedDayOfWeek: DateTime.monday,
        recommendedTimeOfDay: TimeOfDay.morning,
        reasoning: 'Morning workouts help establish a consistent routine.',
      );
    }

    final bestPerformanceDays = _analyzeBestPerformanceDays(recentWorkouts);
    final preferredTimes = _analyzePreferredTimes(recentWorkouts);

    return TimeRecommendation(
      recommendedDayOfWeek: bestPerformanceDays.first,
      recommendedTimeOfDay: preferredTimes.first,
      reasoning: _generateTimingReasoning(bestPerformanceDays, preferredTimes),
    );
  }

  /// Analyzes workout patterns and returns insights.
  WorkoutPatternAnalysis _analyzeWorkoutPatterns(
    List<WorkoutSession> workouts,
  ) {
    // Exercise frequency analysis
    final exerciseFrequency = <String, int>{};
    final exerciseLastSeen = <String, DateTime>{};
    final muscleGroupFrequency = <String, int>{};

    double totalVolume = 0;
    int totalSets = 0;
    int totalWorkouts = workouts.length;

    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        // Track exercise frequency
        exerciseFrequency[exercise.exerciseName] =
            (exerciseFrequency[exercise.exerciseName] ?? 0) + 1;

        // Track last time exercise was performed
        if (workout.completedAt != null) {
          final existing = exerciseLastSeen[exercise.exerciseName];
          if (existing == null || workout.completedAt!.isAfter(existing)) {
            exerciseLastSeen[exercise.exerciseName] = workout.completedAt!;
          }
        }

        // Track muscle groups (simplified categorization)
        final muscleGroup = _categorizeMuscleGroup(exercise.exerciseName);
        muscleGroupFrequency[muscleGroup] =
            (muscleGroupFrequency[muscleGroup] ?? 0) + 1;

        // Calculate volume
        for (final set in exercise.sets) {
          totalSets++;
          totalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
        }
      }
    }

    final avgVolume = totalVolume / totalWorkouts;
    final avgSetsPerWorkout = totalSets / totalWorkouts;

    return WorkoutPatternAnalysis(
      exerciseFrequency: exerciseFrequency,
      exerciseLastSeen: exerciseLastSeen,
      muscleGroupFrequency: muscleGroupFrequency,
      averageVolume: avgVolume,
      averageSetsPerWorkout: avgSetsPerWorkout,
      totalWorkouts: totalWorkouts,
    );
  }

  /// Suggests exercises to balance training.
  List<ExerciseSuggestion> _suggestNextExercises(
    WorkoutPatternAnalysis analysis,
  ) {
    final suggestions = <ExerciseSuggestion>[];
    final now = DateTime.now();

    // Find under-trained muscle groups
    final sortedMuscleGroups = analysis.muscleGroupFrequency.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Suggest exercises for under-trained muscle groups
    for (final group in sortedMuscleGroups.take(3)) {
      final exercises = _getExercisesForMuscleGroup(group.key);

      for (final exercise in exercises) {
        final lastSeen = analysis.exerciseLastSeen[exercise];
        final daysSinceLastPerformed =
            lastSeen != null ? now.difference(lastSeen).inDays : 999;

        suggestions.add(ExerciseSuggestion(
          exerciseName: exercise,
          muscleGroup: group.key,
          priority: _calculatePriority(
            daysSinceLastPerformed,
            group.value,
            analysis.totalWorkouts,
          ),
          reasoning: _getExerciseReasoning(
            exercise,
            group.key,
            daysSinceLastPerformed,
          ),
        ));
      }
    }

    // Sort by priority and return top suggestions
    suggestions.sort((a, b) => b.priority.compareTo(a.priority));
    return suggestions.take(10).toList();
  }

  /// Calculates optimal rest days based on training frequency.
  int _calculateOptimalRestDays(WorkoutPatternAnalysis analysis) {
    final workoutsPerWeek =
        analysis.totalWorkouts / 2; // Assuming 2 week history

    if (workoutsPerWeek >= 6) return 1;
    if (workoutsPerWeek >= 5) return 1;
    if (workoutsPerWeek >= 4) return 2;
    if (workoutsPerWeek >= 3) return 2;
    return 3;
  }

  /// Suggests workout duration based on recent performance.
  int _suggestWorkoutDuration(WorkoutPatternAnalysis analysis) {
    // Base recommendation on average sets
    if (analysis.averageSetsPerWorkout > 25) return 90;
    if (analysis.averageSetsPerWorkout > 20) return 75;
    if (analysis.averageSetsPerWorkout > 15) return 60;
    return 45;
  }

  /// Suggests volume adjustments for progressive overload.
  VolumeAdjustment _suggestVolumeAdjustment(WorkoutPatternAnalysis analysis) {
    // Simplified logic - in real app, would track trends
    if (analysis.averageVolume > 15000) {
      return VolumeAdjustment.decrease;
    } else if (analysis.averageVolume < 5000) {
      return VolumeAdjustment.increase;
    }
    return VolumeAdjustment.maintain;
  }

  /// Generates reasoning for recommendations.
  String _generateReasoning(WorkoutPatternAnalysis analysis) {
    final buffer = StringBuffer();

    buffer.write(
        'Based on your training pattern over ${analysis.totalWorkouts} workouts: ');

    // Volume analysis
    if (analysis.averageVolume > 15000) {
      buffer.write('Your volume is high - focus on recovery and technique. ');
    } else if (analysis.averageVolume < 5000) {
      buffer.write('Consider gradually increasing training volume. ');
    }

    // Balance analysis
    final underTrainedGroups = analysis.muscleGroupFrequency.entries
        .where((e) => e.value < analysis.totalWorkouts * 0.3)
        .map((e) => e.key)
        .toList();

    if (underTrainedGroups.isNotEmpty) {
      buffer.write(
          'Focus on ${underTrainedGroups.join(", ")} for better balance.');
    }

    return buffer.toString();
  }

  /// Suggests muscle groups to target next.
  List<String> _suggestMuscleGroups(WorkoutPatternAnalysis analysis) {
    final sorted = analysis.muscleGroupFrequency.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  /// Categorizes exercise into muscle group.
  String _categorizeMuscleGroup(String exerciseName) {
    final lower = exerciseName.toLowerCase();

    if (lower.contains('squat') ||
        lower.contains('leg') ||
        lower.contains('quad')) {
      return 'Legs';
    }
    if (lower.contains('bench') ||
        lower.contains('chest') ||
        lower.contains('press')) {
      return 'Chest';
    }
    if (lower.contains('row') ||
        lower.contains('pull') ||
        lower.contains('back')) {
      return 'Back';
    }
    if (lower.contains('shoulder') ||
        lower.contains('lateral') ||
        lower.contains('overhead')) {
      return 'Shoulders';
    }
    if (lower.contains('curl') || lower.contains('bicep')) {
      return 'Arms';
    }
    if (lower.contains('deadlift')) {
      return 'Back';
    }

    return 'Other';
  }

  /// Returns default beginner exercises.
  List<ExerciseSuggestion> _getDefaultExercises() {
    return [
      ExerciseSuggestion(
        exerciseName: 'Barbell Squat',
        muscleGroup: 'Legs',
        priority: 10,
        reasoning: 'Fundamental compound exercise for lower body strength',
      ),
      ExerciseSuggestion(
        exerciseName: 'Bench Press',
        muscleGroup: 'Chest',
        priority: 9,
        reasoning: 'Essential upper body compound movement',
      ),
      ExerciseSuggestion(
        exerciseName: 'Deadlift',
        muscleGroup: 'Back',
        priority: 9,
        reasoning: 'Full body compound exercise',
      ),
      ExerciseSuggestion(
        exerciseName: 'Overhead Press',
        muscleGroup: 'Shoulders',
        priority: 8,
        reasoning: 'Key shoulder development exercise',
      ),
    ];
  }

  /// Returns exercises for a specific muscle group.
  List<String> _getExercisesForMuscleGroup(String muscleGroup) {
    switch (muscleGroup) {
      case 'Legs':
        return ['Barbell Squat', 'Leg Press', 'Romanian Deadlift', 'Lunges'];
      case 'Chest':
        return [
          'Bench Press',
          'Incline Bench Press',
          'Dumbbell Flyes',
          'Push-ups'
        ];
      case 'Back':
        return ['Barbell Row', 'Pull-ups', 'Lat Pulldown', 'Deadlift'];
      case 'Shoulders':
        return [
          'Overhead Press',
          'Lateral Raises',
          'Face Pulls',
          'Arnold Press'
        ];
      case 'Arms':
        return [
          'Barbell Curl',
          'Tricep Dips',
          'Hammer Curls',
          'Skull Crushers'
        ];
      default:
        return ['Plank', 'Hanging Leg Raises', 'Cable Crunches'];
    }
  }

  /// Calculates exercise priority score.
  int _calculatePriority(int daysSinceLast, int frequency, int totalWorkouts) {
    // Higher priority for exercises not done recently
    int priority = daysSinceLast ~/ 7; // Weekly basis

    // Lower priority if done frequently
    if (frequency > totalWorkouts * 0.5) {
      priority -= 2;
    }

    return priority.clamp(1, 10);
  }

  /// Generates reasoning for exercise suggestion.
  String _getExerciseReasoning(
    String exercise,
    String muscleGroup,
    int daysSinceLast,
  ) {
    if (daysSinceLast > 14) {
      return 'Last performed ${daysSinceLast} days ago - time to target $muscleGroup again';
    }
    if (daysSinceLast > 7) {
      return 'Good time to work $muscleGroup - adequate recovery time';
    }
    return 'Balance your training with $muscleGroup exercises';
  }

  /// Analyzes best performance days.
  List<int> _analyzeBestPerformanceDays(List<WorkoutSession> workouts) {
    final dayPerformance = <int, double>{};

    for (final workout in workouts) {
      if (workout.completedAt == null) continue;

      final day = workout.completedAt!.weekday;
      double volume = 0;

      for (final exercise in workout.exercises) {
        for (final set in exercise.sets) {
          volume += (set.weightKg ?? 0) * (set.reps ?? 0);
        }
      }

      dayPerformance[day] = (dayPerformance[day] ?? 0) + volume;
    }

    final sorted = dayPerformance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.isEmpty
        ? [DateTime.monday]
        : sorted.map((e) => e.key).toList();
  }

  /// Analyzes preferred workout times.
  List<TimeOfDay> _analyzePreferredTimes(List<WorkoutSession> workouts) {
    final timeDistribution = <TimeOfDay, int>{};

    for (final workout in workouts) {
      final hour = workout.startedAt.hour;
      final timeOfDay = _categorizeTimeOfDay(hour);
      timeDistribution[timeOfDay] = (timeDistribution[timeOfDay] ?? 0) + 1;
    }

    final sorted = timeDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.isEmpty
        ? [TimeOfDay.morning]
        : sorted.map((e) => e.key).toList();
  }

  /// Categorizes hour into time of day.
  TimeOfDay _categorizeTimeOfDay(int hour) {
    if (hour < 12) return TimeOfDay.morning;
    if (hour < 17) return TimeOfDay.afternoon;
    return TimeOfDay.evening;
  }

  /// Generates timing recommendation reasoning.
  String _generateTimingReasoning(
    List<int> bestDays,
    List<TimeOfDay> bestTimes,
  ) {
    final dayNames = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };

    final timeNames = {
      TimeOfDay.morning: 'morning',
      TimeOfDay.afternoon: 'afternoon',
      TimeOfDay.evening: 'evening',
    };

    return 'Your best performance is typically on ${dayNames[bestDays.first]} '
        'in the ${timeNames[bestTimes.first]}.';
  }
}

/// Complete workout recommendations.
class WorkoutRecommendations {
  final List<ExerciseSuggestion> suggestedExercises;
  final int optimalRestDays;
  final int suggestedDuration;
  final VolumeAdjustment volumeAdjustment;
  final String reasoning;
  final List<String>? muscleGroupSuggestions;

  const WorkoutRecommendations({
    required this.suggestedExercises,
    required this.optimalRestDays,
    required this.suggestedDuration,
    required this.volumeAdjustment,
    required this.reasoning,
    this.muscleGroupSuggestions,
  });
}

/// Individual exercise suggestion.
class ExerciseSuggestion {
  final String exerciseName;
  final String muscleGroup;
  final int priority;
  final String reasoning;

  const ExerciseSuggestion({
    required this.exerciseName,
    required this.muscleGroup,
    required this.priority,
    required this.reasoning,
  });
}

/// Workout timing recommendation.
class TimeRecommendation {
  final int recommendedDayOfWeek;
  final TimeOfDay recommendedTimeOfDay;
  final String reasoning;

  const TimeRecommendation({
    required this.recommendedDayOfWeek,
    required this.recommendedTimeOfDay,
    required this.reasoning,
  });
}

/// Workout pattern analysis result.
class WorkoutPatternAnalysis {
  final Map<String, int> exerciseFrequency;
  final Map<String, DateTime> exerciseLastSeen;
  final Map<String, int> muscleGroupFrequency;
  final double averageVolume;
  final double averageSetsPerWorkout;
  final int totalWorkouts;

  const WorkoutPatternAnalysis({
    required this.exerciseFrequency,
    required this.exerciseLastSeen,
    required this.muscleGroupFrequency,
    required this.averageVolume,
    required this.averageSetsPerWorkout,
    required this.totalWorkouts,
  });
}

/// Volume adjustment recommendation.
enum VolumeAdjustment {
  increase,
  maintain,
  decrease,
}

/// Time of day categories.
enum TimeOfDay {
  morning,
  afternoon,
  evening,
}
