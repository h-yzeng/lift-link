import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';

void main() {
  group('WorkoutSession', () {
    WorkoutSet createSet({
      String id = 'set-1',
      double weightKg = 100.0,
      int reps = 10,
      bool isWarmup = false,
    }) {
      return WorkoutSet(
        id: id,
        exercisePerformanceId: 'perf-id',
        setNumber: 1,
        reps: reps,
        weightKg: weightKg,
        isWarmup: isWarmup,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    ExercisePerformance createPerformance({
      String id = 'perf-1',
      String exerciseName = 'Bench Press',
      List<WorkoutSet>? sets,
    }) {
      return ExercisePerformance(
        id: id,
        workoutSessionId: 'session-id',
        exerciseId: 'exercise-id',
        exerciseName: exerciseName,
        orderIndex: 0,
        sets: sets ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    WorkoutSession createSession({
      List<ExercisePerformance>? exercises,
      DateTime? startedAt,
      DateTime? completedAt,
      int? durationMinutes,
    }) {
      return WorkoutSession(
        id: 'session-id',
        userId: 'user-id',
        title: 'Test Workout',
        startedAt: startedAt ?? DateTime.now().subtract(const Duration(hours: 1)),
        completedAt: completedAt,
        durationMinutes: durationMinutes,
        exercises: exercises ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    group('isInProgress / isCompleted', () {
      test('isInProgress is true when completedAt is null', () {
        final session = createSession(completedAt: null);
        expect(session.isInProgress, isTrue);
        expect(session.isCompleted, isFalse);
      });

      test('isCompleted is true when completedAt is set', () {
        final session = createSession(completedAt: DateTime.now());
        expect(session.isCompleted, isTrue);
        expect(session.isInProgress, isFalse);
      });
    });

    group('actualDuration', () {
      test('returns stored durationMinutes if available', () {
        final session = createSession(durationMinutes: 45);
        expect(session.actualDuration, equals(45));
      });

      test('calculates from start to completed time', () {
        final start = DateTime(2025, 1, 1, 10, 0);
        final end = DateTime(2025, 1, 1, 11, 30);
        final session = createSession(startedAt: start, completedAt: end);

        expect(session.actualDuration, equals(90));
      });
    });

    group('formattedDuration', () {
      test('formats minutes only for < 60 min', () {
        final session = createSession(durationMinutes: 45);
        expect(session.formattedDuration, equals('45m'));
      });

      test('formats hours and minutes for >= 60 min', () {
        final session = createSession(durationMinutes: 90);
        expect(session.formattedDuration, equals('1h 30m'));
      });

      test('formats whole hours correctly', () {
        final session = createSession(durationMinutes: 120);
        expect(session.formattedDuration, equals('2h 0m'));
      });
    });

    group('exerciseCount', () {
      test('returns number of exercises', () {
        final session = createSession(exercises: [
          createPerformance(id: 'p1'),
          createPerformance(id: 'p2'),
          createPerformance(id: 'p3'),
        ],);

        expect(session.exerciseCount, equals(3));
      });

      test('returns zero for empty workout', () {
        final session = createSession(exercises: []);
        expect(session.exerciseCount, equals(0));
      });
    });

    group('totalSets', () {
      test('sums sets across all exercises', () {
        final session = createSession(exercises: [
          createPerformance(id: 'p1', sets: [
            createSet(id: 's1'),
            createSet(id: 's2'),
          ],),
          createPerformance(id: 'p2', sets: [
            createSet(id: 's3'),
            createSet(id: 's4'),
            createSet(id: 's5'),
          ],),
        ],);

        expect(session.totalSets, equals(5));
      });

      test('returns zero for empty workout', () {
        final session = createSession(exercises: []);
        expect(session.totalSets, equals(0));
      });
    });

    group('totalWorkingSets', () {
      test('excludes warmup sets', () {
        final session = createSession(exercises: [
          createPerformance(id: 'p1', sets: [
            createSet(id: 's1', isWarmup: true),
            createSet(id: 's2', isWarmup: true),
            createSet(id: 's3'),
          ],),
          createPerformance(id: 'p2', sets: [
            createSet(id: 's4'),
            createSet(id: 's5'),
          ],),
        ],);

        expect(session.totalWorkingSets, equals(3));
      });
    });

    group('totalVolume', () {
      test('sums volume from all exercises', () {
        final session = createSession(exercises: [
          createPerformance(id: 'p1', sets: [
            createSet(id: 's1', weightKg: 100.0, reps: 10), // 1000
          ],),
          createPerformance(id: 'p2', sets: [
            createSet(id: 's2', weightKg: 50.0, reps: 20), // 1000
          ],),
        ],);

        expect(session.totalVolume, equals(2000.0));
      });

      test('returns zero for empty workout', () {
        final session = createSession(exercises: []);
        expect(session.totalVolume, equals(0.0));
      });
    });

    group('formattedTotalVolume', () {
      test('formats in kg for < 1000 kg', () {
        final session = createSession(exercises: [
          createPerformance(sets: [
            createSet(weightKg: 50.0, reps: 10), // 500
          ],),
        ],);

        expect(session.formattedTotalVolume, equals('500 kg'));
      });

      test('formats in tonnes for >= 1000 kg', () {
        final session = createSession(exercises: [
          createPerformance(sets: [
            createSet(weightKg: 100.0, reps: 50), // 5000
          ],),
        ],);

        expect(session.formattedTotalVolume, equals('5.0t'));
      });
    });

    group('totalReps', () {
      test('sums reps from all exercises', () {
        final session = createSession(exercises: [
          createPerformance(id: 'p1', sets: [
            createSet(id: 's1', reps: 10),
            createSet(id: 's2', reps: 8),
          ],),
          createPerformance(id: 'p2', sets: [
            createSet(id: 's3', reps: 12),
          ],),
        ],);

        expect(session.totalReps, equals(30));
      });
    });

    group('personalRecords', () {
      test('maps exercise names to max 1RM', () {
        final session = createSession(exercises: [
          createPerformance(
            id: 'p1',
            exerciseName: 'Bench Press',
            sets: [createSet(id: 's1', weightKg: 100.0, reps: 5)],
          ),
          createPerformance(
            id: 'p2',
            exerciseName: 'Squat',
            sets: [createSet(id: 's2', weightKg: 150.0, reps: 5)],
          ),
        ],);

        final prs = session.personalRecords;
        expect(prs.length, equals(2));
        expect(prs['Bench Press'], closeTo(116.67, 0.01));
        expect(prs['Squat'], closeTo(175.0, 0.01));
      });

      test('excludes exercises with no valid 1RM', () {
        final session = createSession(exercises: [
          createPerformance(
            id: 'p1',
            exerciseName: 'Bench Press',
            sets: [createSet(id: 's1', isWarmup: true)],
          ),
        ],);

        expect(session.personalRecords, isEmpty);
      });
    });

    group('highestOneRM', () {
      test('returns highest 1RM across all exercises', () {
        final session = createSession(exercises: [
          createPerformance(id: 'p1', sets: [
            createSet(id: 's1', weightKg: 100.0, reps: 5), // 116.67
          ],),
          createPerformance(id: 'p2', sets: [
            createSet(id: 's2', weightKg: 150.0, reps: 5), // 175.0
          ],),
        ],);

        expect(session.highestOneRM, closeTo(175.0, 0.01));
      });

      test('returns null when no valid 1RMs', () {
        final session = createSession(exercises: []);
        expect(session.highestOneRM, isNull);
      });
    });

    group('personalRecordsCount', () {
      test('counts exercises with valid 1RM', () {
        final session = createSession(exercises: [
          createPerformance(id: 'p1', exerciseName: 'Bench', sets: [
            createSet(id: 's1', weightKg: 100.0, reps: 5),
          ],),
          createPerformance(id: 'p2', exerciseName: 'Squat', sets: [
            createSet(id: 's2', weightKg: 150.0, reps: 5),
          ],),
          createPerformance(id: 'p3', exerciseName: 'Warmup Only', sets: [
            createSet(id: 's3', isWarmup: true),
          ],),
        ],);

        expect(session.personalRecordsCount, equals(2));
      });
    });

    group('duration', () {
      test('returns Duration from durationMinutes', () {
        final session = createSession(durationMinutes: 60);
        expect(session.duration, equals(const Duration(minutes: 60)));
      });

      test('calculates from startedAt to completedAt', () {
        final start = DateTime(2025, 1, 1, 10, 0);
        final end = DateTime(2025, 1, 1, 11, 0);
        final session = createSession(
          startedAt: start,
          completedAt: end,
          durationMinutes: null,
        );

        expect(session.duration, equals(const Duration(hours: 1)));
      });
    });
  });
}
