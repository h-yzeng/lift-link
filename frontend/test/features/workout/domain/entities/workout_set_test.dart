import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';

void main() {
  group('WorkoutSet', () {
    WorkoutSet createSet({
      double weightKg = 100.0,
      int reps = 10,
      bool isWarmup = false,
      double? rpe,
    }) {
      return WorkoutSet(
        id: 'test-set-id',
        exercisePerformanceId: 'test-perf-id',
        setNumber: 1,
        reps: reps,
        weightKg: weightKg,
        isWarmup: isWarmup,
        rpe: rpe,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    group('calculated1RM', () {
      test('calculates 1RM using Epley formula', () {
        final set = createSet(weightKg: 100.0, reps: 10);
        // Epley: 100 * (1 + 10/30) = 100 * 1.333... = 133.33...
        expect(set.calculated1RM, closeTo(133.33, 0.01));
      });

      test('returns exact weight for 1 rep', () {
        final set = createSet(weightKg: 150.0, reps: 1);
        // Epley: 150 * (1 + 1/30) = 150 * 1.033... = 155.0
        expect(set.calculated1RM, closeTo(155.0, 0.01));
      });

      test('returns null for warmup sets', () {
        final set = createSet(weightKg: 100.0, reps: 10, isWarmup: true);
        expect(set.calculated1RM, isNull);
      });

      test('returns null for zero weight', () {
        final set = createSet(weightKg: 0.0, reps: 10);
        expect(set.calculated1RM, isNull);
      });

      test('returns null for zero reps', () {
        final set = createSet(weightKg: 100.0, reps: 0);
        expect(set.calculated1RM, isNull);
      });

      test('returns null for negative weight', () {
        final set = createSet(weightKg: -50.0, reps: 10);
        expect(set.calculated1RM, isNull);
      });

      test('returns null for reps > 30 (unreliable range)', () {
        final set = createSet(weightKg: 50.0, reps: 31);
        expect(set.calculated1RM, isNull);
      });

      test('calculates correctly at boundary (30 reps)', () {
        final set = createSet(weightKg: 50.0, reps: 30);
        // Epley: 50 * (1 + 30/30) = 50 * 2 = 100
        expect(set.calculated1RM, equals(100.0));
      });
    });

    group('formatted1RM', () {
      test('formats 1RM with kg suffix', () {
        final set = createSet(weightKg: 100.0, reps: 10);
        expect(set.formatted1RM, equals('133.3 kg'));
      });

      test('returns N/A for warmup sets', () {
        final set = createSet(weightKg: 100.0, reps: 10, isWarmup: true);
        expect(set.formatted1RM, equals('N/A'));
      });

      test('returns N/A for invalid data', () {
        final set = createSet(weightKg: 0.0, reps: 0);
        expect(set.formatted1RM, equals('N/A'));
      });
    });

    group('isWorkingSet', () {
      test('returns true for non-warmup sets', () {
        final set = createSet(isWarmup: false);
        expect(set.isWorkingSet, isTrue);
      });

      test('returns false for warmup sets', () {
        final set = createSet(isWarmup: true);
        expect(set.isWorkingSet, isFalse);
      });
    });

    group('volume', () {
      test('calculates volume as weight × reps', () {
        final set = createSet(weightKg: 100.0, reps: 10);
        expect(set.volume, equals(1000.0));
      });

      test('handles zero reps', () {
        final set = createSet(weightKg: 100.0, reps: 0);
        expect(set.volume, equals(0.0));
      });

      test('handles zero weight', () {
        final set = createSet(weightKg: 0.0, reps: 10);
        expect(set.volume, equals(0.0));
      });
    });

    group('formattedWeight', () {
      test('formats weight with kg suffix', () {
        final set = createSet(weightKg: 100.5);
        expect(set.formattedWeight, equals('100.5 kg'));
      });

      test('formats whole numbers correctly', () {
        final set = createSet(weightKg: 100.0);
        expect(set.formattedWeight, equals('100.0 kg'));
      });
    });

    group('formattedRpe', () {
      test('formats RPE with prefix', () {
        final set = createSet(rpe: 8.5);
        expect(set.formattedRpe, equals('RPE 8.5'));
      });

      test('returns null when RPE is not set', () {
        final set = createSet(rpe: null);
        expect(set.formattedRpe, isNull);
      });

      test('formats whole number RPE', () {
        final set = createSet(rpe: 9.0);
        expect(set.formattedRpe, equals('RPE 9.0'));
      });
    });
  });
}
