import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';

void main() {
  group('ExercisePerformance', () {
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

    ExercisePerformance createPerformance({List<WorkoutSet>? sets}) {
      return ExercisePerformance(
        id: 'perf-id',
        workoutSessionId: 'session-id',
        exerciseId: 'exercise-id',
        exerciseName: 'Bench Press',
        orderIndex: 0,
        sets: sets ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    group('maxOneRM', () {
      test('returns highest 1RM from working sets', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', weightKg: 80.0, reps: 10), // 1RM: 106.67
          createSet(id: 's2', weightKg: 100.0, reps: 5), // 1RM: 116.67
          createSet(id: 's3', weightKg: 90.0, reps: 8), // 1RM: 114.0
        ],);

        expect(performance.maxOneRM, closeTo(116.67, 0.01));
      });

      test('excludes warmup sets from calculation', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', weightKg: 50.0, reps: 10, isWarmup: true),
          createSet(id: 's2', weightKg: 100.0, reps: 5), // 1RM: 116.67
        ],);

        expect(performance.maxOneRM, closeTo(116.67, 0.01));
      });

      test('returns null when no working sets', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', weightKg: 50.0, reps: 10, isWarmup: true),
        ],);

        expect(performance.maxOneRM, isNull);
      });

      test('returns null for empty sets list', () {
        final performance = createPerformance(sets: []);
        expect(performance.maxOneRM, isNull);
      });
    });

    group('formattedMaxOneRM', () {
      test('formats max 1RM with kg suffix', () {
        final performance = createPerformance(sets: [
          createSet(weightKg: 100.0, reps: 10),
        ],);

        expect(performance.formattedMaxOneRM, equals('133.3 kg'));
      });

      test('returns N/A when no valid 1RM', () {
        final performance = createPerformance(sets: []);
        expect(performance.formattedMaxOneRM, equals('N/A'));
      });
    });

    group('totalVolume', () {
      test('sums volume from all sets', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', weightKg: 100.0, reps: 10), // 1000
          createSet(id: 's2', weightKg: 100.0, reps: 8), // 800
          createSet(id: 's3', weightKg: 100.0, reps: 6), // 600
        ],);

        expect(performance.totalVolume, equals(2400.0));
      });

      test('includes warmup sets in volume', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', weightKg: 50.0, reps: 10, isWarmup: true), // 500
          createSet(id: 's2', weightKg: 100.0, reps: 10), // 1000
        ],);

        expect(performance.totalVolume, equals(1500.0));
      });

      test('returns zero for empty sets', () {
        final performance = createPerformance(sets: []);
        expect(performance.totalVolume, equals(0.0));
      });
    });

    group('set counts', () {
      test('workingSetsCount excludes warmups', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', isWarmup: true),
          createSet(id: 's2', isWarmup: true),
          createSet(id: 's3', isWarmup: false),
          createSet(id: 's4', isWarmup: false),
          createSet(id: 's5', isWarmup: false),
        ],);

        expect(performance.workingSetsCount, equals(3));
      });

      test('warmupSetsCount only counts warmups', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', isWarmup: true),
          createSet(id: 's2', isWarmup: true),
          createSet(id: 's3', isWarmup: false),
        ],);

        expect(performance.warmupSetsCount, equals(2));
      });

      test('totalSetsCount counts all sets', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', isWarmup: true),
          createSet(id: 's2', isWarmup: false),
          createSet(id: 's3', isWarmup: false),
        ],);

        expect(performance.totalSetsCount, equals(3));
      });
    });

    group('totalReps', () {
      test('sums reps from working sets only', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', reps: 10, isWarmup: true),
          createSet(id: 's2', reps: 10),
          createSet(id: 's3', reps: 8),
          createSet(id: 's4', reps: 6),
        ],);

        expect(performance.totalReps, equals(24)); // 10 + 8 + 6
      });

      test('returns zero when only warmup sets', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', reps: 10, isWarmup: true),
        ],);

        expect(performance.totalReps, equals(0));
      });
    });

    group('averageWeight', () {
      test('calculates average weight of working sets', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', weightKg: 100.0),
          createSet(id: 's2', weightKg: 110.0),
          createSet(id: 's3', weightKg: 120.0),
        ],);

        expect(performance.averageWeight, equals(110.0));
      });

      test('excludes warmup sets from average', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', weightKg: 50.0, isWarmup: true),
          createSet(id: 's2', weightKg: 100.0),
          createSet(id: 's3', weightKg: 100.0),
        ],);

        expect(performance.averageWeight, equals(100.0));
      });

      test('returns null when no working sets', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', weightKg: 50.0, isWarmup: true),
        ],);

        expect(performance.averageWeight, isNull);
      });
    });

    group('maxWeight', () {
      test('returns highest weight from working sets', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', weightKg: 100.0),
          createSet(id: 's2', weightKg: 120.0),
          createSet(id: 's3', weightKg: 110.0),
        ],);

        expect(performance.maxWeight, equals(120.0));
      });

      test('excludes warmup sets', () {
        final performance = createPerformance(sets: [
          createSet(id: 's1', weightKg: 200.0, isWarmup: true),
          createSet(id: 's2', weightKg: 100.0),
        ],);

        expect(performance.maxWeight, equals(100.0));
      });

      test('returns null when no working sets', () {
        final performance = createPerformance(sets: []);
        expect(performance.maxWeight, isNull);
      });
    });
  });
}
