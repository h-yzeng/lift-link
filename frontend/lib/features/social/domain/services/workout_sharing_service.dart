import 'package:share_plus/share_plus.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:intl/intl.dart';

/// Service for sharing workout sessions and creating social posts.
///
/// Provides functionality to:
/// - Generate formatted workout summaries
/// - Share workouts to social media
/// - Create achievement posts
/// - Share workout stats with friends
///
/// Example usage:
/// ```dart
/// final service = WorkoutSharingService();
/// await service.shareWorkoutSummary(workout, useImperialUnits: true);
/// ```
class WorkoutSharingService {
  /// Shares a workout summary with formatted text.
  ///
  /// Generates a human-readable workout summary including:
  /// - Workout title and date
  /// - Duration and exercise count
  /// - Detailed exercise breakdown
  /// - Total volume statistics
  Future<void> shareWorkoutSummary(
    WorkoutSession workout, {
    bool useImperialUnits = true,
  }) async {
    final summary = generateWorkoutSummary(workout, useImperialUnits);

    await Share.share(
      summary,
      subject: '${workout.title} - LiftLink Workout',
    );
  }

  /// Generates a formatted text summary of a workout.
  String generateWorkoutSummary(
    WorkoutSession workout,
    bool useImperialUnits,
  ) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final weightUnit = useImperialUnits ? 'lbs' : 'kg';

    // Header
    buffer.writeln('💪 ${workout.title}');
    buffer.writeln(dateFormat.format(workout.startedAt));
    buffer.writeln();

    // Summary stats
    buffer.writeln('📊 Workout Summary:');
    buffer.writeln('⏱️  Duration: ${workout.durationMinutes ?? 0} minutes');
    buffer.writeln('🏋️  Exercises: ${workout.exercises.length}');

    // Calculate total volume
    double totalVolume = 0;
    int totalSets = 0;
    int totalReps = 0;

    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        totalSets++;
        totalReps += set.reps;
        totalVolume += set.weightKg * set.reps;
      }
    }

    buffer.writeln(
        '📈 Total Volume: ${totalVolume.toStringAsFixed(0)} $weightUnit',);
    buffer.writeln('🔢 Total Sets: $totalSets');
    buffer.writeln('🔄 Total Reps: $totalReps');
    buffer.writeln();

    // Exercise details
    buffer.writeln('💪 Exercises:');
    for (final exercise in workout.exercises) {
      buffer.writeln();
      buffer.writeln('• ${exercise.exerciseName}');

      for (var i = 0; i < exercise.sets.length; i++) {
        final set = exercise.sets[i];
        final weight = set.weightKg.toStringAsFixed(1);
        final reps = set.reps.toString();
        buffer.writeln('  Set ${i + 1}: $weight $weightUnit × $reps reps');
      }

      if (exercise.notes != null && exercise.notes!.isNotEmpty) {
        buffer.writeln('  📝 ${exercise.notes}');
      }
    }

    // Notes
    if (workout.notes != null && workout.notes!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 Notes:');
      buffer.writeln(workout.notes);
    }

    buffer.writeln();
    buffer.writeln('Tracked with LiftLink 💪');

    return buffer.toString();
  }

  /// Creates a social media achievement post for a workout.
  ///
  /// Generates an engaging post highlighting key achievements:
  /// - Personal records
  /// - Volume milestones
  /// - Consistency streaks
  Future<void> shareAchievementPost(
    WorkoutSession workout, {
    int? currentStreak,
    List<String>? personalRecords,
    bool useImperialUnits = true,
  }) async {
    final post = generateAchievementPost(
      workout,
      currentStreak: currentStreak,
      personalRecords: personalRecords,
      useImperialUnits: useImperialUnits,
    );

    await Share.share(
      post,
      subject: 'My Workout Achievement! 🎉',
    );
  }

  /// Generates an achievement post with emojis and highlights.
  String generateAchievementPost(
    WorkoutSession workout, {
    int? currentStreak,
    List<String>? personalRecords,
    bool useImperialUnits = true,
  }) {
    final buffer = StringBuffer();
    final weightUnit = useImperialUnits ? 'lbs' : 'kg';

    buffer.writeln('🎉 Workout Complete! 🎉');
    buffer.writeln();

    // Streak
    if (currentStreak != null && currentStreak > 0) {
      buffer.writeln('🔥 $currentStreak day streak! Keep it up!');
      buffer.writeln();
    }

    // Workout info
    buffer.writeln('💪 ${workout.title}');
    buffer.writeln('⏱️  ${workout.durationMinutes ?? 0} minutes');
    buffer.writeln();

    // Calculate stats
    double totalVolume = 0;
    int totalSets = 0;

    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        totalSets++;
        totalVolume += set.weightKg * set.reps;
      }
    }

    buffer.writeln('📊 Stats:');
    buffer.writeln('• ${workout.exercises.length} exercises');
    buffer.writeln('• $totalSets total sets');
    buffer.writeln(
        '• ${totalVolume.toStringAsFixed(0)} $weightUnit total volume',);
    buffer.writeln();

    // Personal records
    if (personalRecords != null && personalRecords.isNotEmpty) {
      buffer.writeln('🏆 New Personal Records:');
      for (final pr in personalRecords) {
        buffer.writeln('• $pr');
      }
      buffer.writeln();
    }

    buffer.writeln('#LiftLink #Fitness #Workout #Gains');

    return buffer.toString();
  }

  /// Shares quick stats with a simple message.
  Future<void> shareQuickStats(
    WorkoutSession workout, {
    bool useImperialUnits = true,
  }) async {
    final weightUnit = useImperialUnits ? 'lbs' : 'kg';

    // Calculate total volume
    double totalVolume = 0;
    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        totalVolume += set.weightKg * set.reps;
      }
    }

    final message = '💪 Just crushed ${workout.title}!\n'
        '⏱️ ${workout.durationMinutes} min | '
        '🏋️ ${workout.exercises.length} exercises | '
        '📈 ${totalVolume.toStringAsFixed(0)} $weightUnit volume\n\n'
        'Tracked with LiftLink';

    await Share.share(message);
  }

  /// Shares a comparison between current and previous workout.
  Future<void> shareProgressComparison(
    WorkoutSession currentWorkout,
    WorkoutSession previousWorkout, {
    bool useImperialUnits = true,
  }) async {
    final comparison = generateProgressComparison(
      currentWorkout,
      previousWorkout,
      useImperialUnits,
    );

    await Share.share(
      comparison,
      subject: 'My Workout Progress 📈',
    );
  }

  /// Generates a progress comparison post.
  String generateProgressComparison(
    WorkoutSession currentWorkout,
    WorkoutSession previousWorkout,
    bool useImperialUnits,
  ) {
    final buffer = StringBuffer();
    final weightUnit = useImperialUnits ? 'lbs' : 'kg';

    buffer.writeln('📈 Progress Update!');
    buffer.writeln();
    buffer.writeln('${currentWorkout.title} Comparison:');
    buffer.writeln();

    // Calculate volumes
    double currentVolume = 0;
    double previousVolume = 0;

    for (final exercise in currentWorkout.exercises) {
      for (final set in exercise.sets) {
        currentVolume += set.weightKg * set.reps;
      }
    }

    for (final exercise in previousWorkout.exercises) {
      for (final set in exercise.sets) {
        previousVolume += set.weightKg * set.reps;
      }
    }

    final volumeDiff = currentVolume - previousVolume;
    final volumePercent = previousVolume > 0
        ? (volumeDiff / previousVolume * 100).toStringAsFixed(1)
        : '0.0';

    // Duration
    final currentDuration = currentWorkout.durationMinutes ?? 0;
    final previousDuration = previousWorkout.durationMinutes ?? 0;

    buffer.writeln('Today vs Last Time:');
    buffer.writeln();
    buffer.writeln('📊 Volume:');
    buffer.writeln('  Today: ${currentVolume.toStringAsFixed(0)} $weightUnit');
    buffer.writeln(
        '  Previous: ${previousVolume.toStringAsFixed(0)} $weightUnit',);
    buffer.writeln(
        '  Change: ${volumeDiff > 0 ? '+' : ''}${volumeDiff.toStringAsFixed(0)} $weightUnit (${volumeDiff > 0 ? '+' : ''}$volumePercent%)',);
    buffer.writeln();
    buffer.writeln('⏱️ Duration:');
    buffer.writeln('  Today: $currentDuration min');
    buffer.writeln('  Previous: $previousDuration min');
    buffer.writeln();

    if (volumeDiff > 0) {
      buffer.writeln('🎉 Keep up the great work!');
    } else {
      buffer.writeln('💪 Every workout counts!');
    }

    buffer.writeln();
    buffer.writeln('Tracked with LiftLink');

    return buffer.toString();
  }
}
