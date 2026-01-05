import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/core/services/streak_service.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';

void main() {
  late StreakService streakService;

  setUp(() {
    streakService = StreakService();
  });

  group('calculateStreak', () {
    test('should return zero streak for empty workout list', () {
      // Act
      final result = streakService.calculateStreak([]);

      // Assert
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(result.lastWorkoutDate, isNull);
    });

    test('should calculate streak of 1 for single workout today', () {
      // Arrange
      final today = DateTime.now();
      final workouts = [
        _createWorkout('1', today),
      ];

      // Act
      final result = streakService.calculateStreak(workouts);

      // Assert
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
      expect(result.lastWorkoutDate, isNotNull);
    });

    test('should calculate streak of 3 for consecutive days', () {
      // Arrange
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final workouts = [
        _createWorkout('1', today),
        _createWorkout('2', yesterday),
        _createWorkout('3', twoDaysAgo),
      ];

      // Act
      final result = streakService.calculateStreak(workouts);

      // Assert
      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
    });

    test('should reset current streak when workout was 2+ days ago', () {
      // Arrange
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final fourDaysAgo = DateTime.now().subtract(const Duration(days: 4));

      final workouts = [
        _createWorkout('1', threeDaysAgo),
        _createWorkout('2', fourDaysAgo),
      ];

      // Act
      final result = streakService.calculateStreak(workouts);

      // Assert
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 2);
    });

    test('should find longest streak among multiple streaks', () {
      // Arrange
      final today = DateTime.now();
      final workouts = [
        // Current streak: 2 days
        _createWorkout('1', today),
        _createWorkout('2', today.subtract(const Duration(days: 1))),
        // Gap
        _createWorkout('3', today.subtract(const Duration(days: 5))),
        _createWorkout('4', today.subtract(const Duration(days: 6))),
        _createWorkout('5', today.subtract(const Duration(days: 7))),
        _createWorkout('6', today.subtract(const Duration(days: 8))),
      ];

      // Act
      final result = streakService.calculateStreak(workouts);

      // Assert
      expect(result.currentStreak, 2);
      expect(result.longestStreak, 4); // The 4-day streak from days 5-8
    });

    test('should handle multiple workouts on same day', () {
      // Arrange
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final workouts = [
        _createWorkout('1', today),
        _createWorkout('2', today.add(const Duration(hours: 1))),
        _createWorkout('3', yesterday),
      ];

      // Act
      final result = streakService.calculateStreak(workouts);

      // Assert
      expect(result.currentStreak, 2); // Should count unique days only
      expect(result.longestStreak, 2);
    });

    test('should accept workout from yesterday as current streak', () {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final workouts = [
        _createWorkout('1', yesterday),
      ];

      // Act
      final result = streakService.calculateStreak(workouts);

      // Assert
      expect(result.currentStreak, 1);
    });
  });

  group('checkMilestone', () {
    test('should return null when no milestone crossed', () {
      // Act
      final result = streakService.checkMilestone(2, 2);

      // Assert
      expect(result, isNull);
    });

    test('should return 3 when crossing 3-day milestone', () {
      // Act
      final result = streakService.checkMilestone(2, 3);

      // Assert
      expect(result, 3);
    });

    test('should return 7 when crossing 7-day milestone', () {
      // Act
      final result = streakService.checkMilestone(6, 7);

      // Assert
      expect(result, 7);
    });

    test('should return highest milestone when crossing multiple', () {
      // Act
      final result = streakService.checkMilestone(2, 14);

      // Assert
      expect(result, 14); // Should return the first milestone crossed (3)
    });

    test('should return null when going backwards', () {
      // Act
      final result = streakService.checkMilestone(10, 5);

      // Assert
      expect(result, isNull);
    });
  });

  group('getStreakMessage', () {
    test('should return motivational message for 0 streak', () {
      // Act
      final message = streakService.getStreakMessage(0);

      // Assert
      expect(message, contains('Start'));
    });

    test('should return message for 1-day streak', () {
      // Act
      final message = streakService.getStreakMessage(1);

      // Assert
      expect(message, contains('Great start'));
    });

    test('should return message for 5-day streak', () {
      // Act
      final message = streakService.getStreakMessage(5);

      // Assert
      expect(message, contains('fire'));
    });

    test('should return message for 10-day streak', () {
      // Act
      final message = streakService.getStreakMessage(10);

      // Assert
      expect(message, contains('Incredible'));
    });

    test('should return message for 100+ day streak', () {
      // Act
      final message = streakService.getStreakMessage(100);

      // Assert
      expect(message, contains('Champion'));
    });
  });

  group('getStreakEmoji', () {
    test('should return muscle emoji for 0 streak', () {
      expect(streakService.getStreakEmoji(0), '💪');
    });

    test('should return fire emoji for 3-day streak', () {
      expect(streakService.getStreakEmoji(3), '🔥');
    });

    test('should return lightning emoji for 10-day streak', () {
      expect(streakService.getStreakEmoji(10), '⚡');
    });

    test('should return rocket emoji for 20-day streak', () {
      expect(streakService.getStreakEmoji(20), '🚀');
    });

    test('should return diamond emoji for 50-day streak', () {
      expect(streakService.getStreakEmoji(50), '💎');
    });

    test('should return crown emoji for 100+ day streak', () {
      expect(streakService.getStreakEmoji(100), '👑');
    });
  });

  group('StreakData', () {
    test('should format last workout as Today', () {
      // Arrange
      final today = DateTime.now();
      final streakData = StreakData(
        currentStreak: 1,
        longestStreak: 1,
        lastWorkoutDate: today,
      );

      // Act & Assert
      expect(streakData.lastWorkoutFormatted, 'Today');
    });

    test('should format last workout as Yesterday', () {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final streakData = StreakData(
        currentStreak: 1,
        longestStreak: 1,
        lastWorkoutDate: yesterday,
      );

      // Act & Assert
      expect(streakData.lastWorkoutFormatted, 'Yesterday');
    });

    test('should format last workout as days ago', () {
      // Arrange
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final streakData = StreakData(
        currentStreak: 0,
        longestStreak: 5,
        lastWorkoutDate: threeDaysAgo,
      );

      // Act & Assert
      expect(streakData.lastWorkoutFormatted, '3 days ago');
    });

    test('should format null last workout as Never', () {
      // Arrange
      const streakData = StreakData(
        currentStreak: 0,
        longestStreak: 0,
        lastWorkoutDate: null,
      );

      // Act & Assert
      expect(streakData.lastWorkoutFormatted, 'Never');
    });
  });
}

// Helper function to create test workouts
WorkoutSession _createWorkout(String id, DateTime completedAt) {
  return WorkoutSession(
    id: id,
    userId: 'test-user',
    title: 'Test Workout',
    notes: null,
    startedAt: completedAt.subtract(const Duration(hours: 1)),
    completedAt: completedAt,
    durationMinutes: 60,
    exercises: const [],
    createdAt: completedAt.subtract(const Duration(hours: 1)),
    updatedAt: completedAt,
  );
}
