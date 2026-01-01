import 'package:liftlink/features/workout/domain/entities/workout_session.dart';

/// Service for calculating workout streaks
///
/// A streak is defined as consecutive days where the user completed at least one workout.
/// The streak is broken if there's a gap of more than 1 day between workouts.
class StreakService {
  /// Calculate current and longest workout streaks from a list of completed workouts
  ///
  /// Returns a record with (currentStreak, longestStreak, lastWorkoutDate)
  StreakData calculateStreak(List<WorkoutSession> completedWorkouts) {
    if (completedWorkouts.isEmpty) {
      return StreakData(
        currentStreak: 0,
        longestStreak: 0,
        lastWorkoutDate: null,
      );
    }

    // Extract unique workout dates (ignore time, only care about day)
    final workoutDates = completedWorkouts
        .where((w) => w.completedAt != null)
        .map((w) => _dateOnly(w.completedAt!))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending (most recent first)

    if (workoutDates.isEmpty) {
      return StreakData(
        currentStreak: 0,
        longestStreak: 0,
        lastWorkoutDate: null,
      );
    }

    final lastWorkoutDate = workoutDates.first;
    final today = _dateOnly(DateTime.now());

    // Calculate current streak
    int currentStreak = 0;
    final daysSinceLastWorkout = today.difference(lastWorkoutDate).inDays;

    // Current streak is valid only if last workout was today or yesterday
    if (daysSinceLastWorkout <= 1) {
      currentStreak = 1;
      DateTime previousDate = lastWorkoutDate;

      // Count consecutive days going backwards
      for (int i = 1; i < workoutDates.length; i++) {
        final currentDate = workoutDates[i];
        final daysDiff = previousDate.difference(currentDate).inDays;

        if (daysDiff == 1) {
          // Consecutive day
          currentStreak++;
          previousDate = currentDate;
        } else {
          // Streak broken
          break;
        }
      }
    }

    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 1;
    DateTime? previousDate;

    for (final date in workoutDates) {
      if (previousDate == null) {
        previousDate = date;
        tempStreak = 1;
        longestStreak = 1;
      } else {
        final daysDiff = previousDate.difference(date).inDays;

        if (daysDiff == 1) {
          // Consecutive day
          tempStreak++;
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        } else {
          // Streak broken, reset temp counter
          tempStreak = 1;
        }

        previousDate = date;
      }
    }

    return StreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastWorkoutDate: lastWorkoutDate,
    );
  }

  /// Check if a milestone was reached
  ///
  /// Returns the milestone number if one was reached, null otherwise.
  /// Milestones are at: 3, 7, 14, 30, 60, 90, 180, 365 days
  int? checkMilestone(int oldStreak, int newStreak) {
    const milestones = [3, 7, 14, 30, 60, 90, 180, 365];

    for (final milestone in milestones) {
      if (oldStreak < milestone && newStreak >= milestone) {
        return milestone;
      }
    }

    return null;
  }

  /// Get motivational message based on current streak
  String getStreakMessage(int streak) {
    if (streak == 0) {
      return "Start your streak today!";
    } else if (streak == 1) {
      return "Great start! Keep it going tomorrow.";
    } else if (streak < 7) {
      return "You're on fire! $streak days strong!";
    } else if (streak < 14) {
      return "Incredible! $streak days in a row!";
    } else if (streak < 30) {
      return "Unstoppable! $streak day streak!";
    } else if (streak < 90) {
      return "Legendary! $streak days of dedication!";
    } else {
      return "Champion! $streak day streak!";
    }
  }

  /// Get emoji for current streak
  String getStreakEmoji(int streak) {
    if (streak == 0) {
      return "💪";
    } else if (streak < 7) {
      return "🔥";
    } else if (streak < 14) {
      return "⚡";
    } else if (streak < 30) {
      return "🚀";
    } else if (streak < 90) {
      return "💎";
    } else {
      return "👑";
    }
  }

  /// Helper to get date without time component
  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}

/// Data class for streak information
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWorkoutDate;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastWorkoutDate,
  });

  /// Get formatted string for last workout
  String get lastWorkoutFormatted {
    if (lastWorkoutDate == null) return 'Never';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(
      lastWorkoutDate!.year,
      lastWorkoutDate!.month,
      lastWorkoutDate!.day,
    );

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      final diff = today.difference(dateOnly).inDays;
      return '$diff days ago';
    }
  }

  @override
  String toString() {
    return 'StreakData(current: $currentStreak, longest: $longestStreak, last: $lastWorkoutFormatted)';
  }
}
