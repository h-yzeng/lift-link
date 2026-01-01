import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_set.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';
import 'package:liftlink/features/workout/domain/usecases/add_set_to_exercise.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  late AddSetToExercise useCase;
  late MockWorkoutRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkoutRepository();
    useCase = AddSetToExercise(mockRepository);
  });

  WorkoutSet createSet() {
    return WorkoutSet(
      id: 'set-id',
      exercisePerformanceId: 'perf-id',
      setNumber: 1,
      reps: 10,
      weightKg: 100.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('AddSetToExercise validation', () {
    test('returns ValidationFailure when exercisePerformanceId is empty', () async {
      final result = await useCase(
        exercisePerformanceId: '',
        setNumber: 1,
        reps: 10,
        weightKg: 100.0,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('Exercise performance ID'));
        },
        (_) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns ValidationFailure when setNumber < 1', () async {
      final result = await useCase(
        exercisePerformanceId: 'perf-id',
        setNumber: 0,
        reps: 10,
        weightKg: 100.0,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('Set number'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('returns ValidationFailure when reps is negative', () async {
      final result = await useCase(
        exercisePerformanceId: 'perf-id',
        setNumber: 1,
        reps: -1,
        weightKg: 100.0,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('Reps'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('allows zero reps', () async {
      final set = createSet();
      when(
        () => mockRepository.addSetToExercise(
          exercisePerformanceId: any(named: 'exercisePerformanceId'),
          setNumber: any(named: 'setNumber'),
          reps: any(named: 'reps'),
          weightKg: any(named: 'weightKg'),
          isWarmup: any(named: 'isWarmup'),
          isDropset: any(named: 'isDropset'),
          rpe: any(named: 'rpe'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => Right(set));

      final result = await useCase(
        exercisePerformanceId: 'perf-id',
        setNumber: 1,
        reps: 0,
        weightKg: 100.0,
      );

      expect(result.isRight(), isTrue);
    });

    test('returns ValidationFailure when weight is negative', () async {
      final result = await useCase(
        exercisePerformanceId: 'perf-id',
        setNumber: 1,
        reps: 10,
        weightKg: -50.0,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('Weight'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('allows zero weight (bodyweight exercises)', () async {
      final set = createSet();
      when(
        () => mockRepository.addSetToExercise(
          exercisePerformanceId: any(named: 'exercisePerformanceId'),
          setNumber: any(named: 'setNumber'),
          reps: any(named: 'reps'),
          weightKg: any(named: 'weightKg'),
          isWarmup: any(named: 'isWarmup'),
          isDropset: any(named: 'isDropset'),
          rpe: any(named: 'rpe'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => Right(set));

      final result = await useCase(
        exercisePerformanceId: 'perf-id',
        setNumber: 1,
        reps: 10,
        weightKg: 0.0,
      );

      expect(result.isRight(), isTrue);
    });

    test('returns ValidationFailure when RPE < 0', () async {
      final result = await useCase(
        exercisePerformanceId: 'perf-id',
        setNumber: 1,
        reps: 10,
        weightKg: 100.0,
        rpe: -1.0,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('RPE'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('returns ValidationFailure when RPE > 10', () async {
      final result = await useCase(
        exercisePerformanceId: 'perf-id',
        setNumber: 1,
        reps: 10,
        weightKg: 100.0,
        rpe: 11.0,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('RPE'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('allows RPE at boundaries (0 and 10)', () async {
      final set = createSet();
      when(
        () => mockRepository.addSetToExercise(
          exercisePerformanceId: any(named: 'exercisePerformanceId'),
          setNumber: any(named: 'setNumber'),
          reps: any(named: 'reps'),
          weightKg: any(named: 'weightKg'),
          isWarmup: any(named: 'isWarmup'),
          isDropset: any(named: 'isDropset'),
          rpe: any(named: 'rpe'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => Right(set));

      // Test RPE = 0
      var result = await useCase(
        exercisePerformanceId: 'perf-id',
        setNumber: 1,
        reps: 10,
        weightKg: 100.0,
        rpe: 0.0,
      );
      expect(result.isRight(), isTrue);

      // Test RPE = 10
      result = await useCase(
        exercisePerformanceId: 'perf-id',
        setNumber: 1,
        reps: 10,
        weightKg: 100.0,
        rpe: 10.0,
      );
      expect(result.isRight(), isTrue);
    });
  });

  group('AddSetToExercise success', () {
    test('calls repository with all parameters', () async {
      final set = createSet();
      when(
        () => mockRepository.addSetToExercise(
          exercisePerformanceId: any(named: 'exercisePerformanceId'),
          setNumber: any(named: 'setNumber'),
          reps: any(named: 'reps'),
          weightKg: any(named: 'weightKg'),
          isWarmup: any(named: 'isWarmup'),
          isDropset: any(named: 'isDropset'),
          rpe: any(named: 'rpe'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => Right(set));

      await useCase(
        exercisePerformanceId: 'perf-123',
        setNumber: 3,
        reps: 8,
        weightKg: 120.0,
        isWarmup: true,
        isDropset: false,
        rpe: 7.5,
        notes: 'Felt strong',
      );

      verify(
        () => mockRepository.addSetToExercise(
          exercisePerformanceId: 'perf-123',
          setNumber: 3,
          reps: 8,
          weightKg: 120.0,
          isWarmup: true,
          isDropset: false,
          rpe: 7.5,
          notes: 'Felt strong',
        ),
      ).called(1);
    });

    test('returns WorkoutSet on success', () async {
      final set = createSet();
      when(
        () => mockRepository.addSetToExercise(
          exercisePerformanceId: any(named: 'exercisePerformanceId'),
          setNumber: any(named: 'setNumber'),
          reps: any(named: 'reps'),
          weightKg: any(named: 'weightKg'),
          isWarmup: any(named: 'isWarmup'),
          isDropset: any(named: 'isDropset'),
          rpe: any(named: 'rpe'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => Right(set));

      final result = await useCase(
        exercisePerformanceId: 'perf-id',
        setNumber: 1,
        reps: 10,
        weightKg: 100.0,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return success'),
        (workoutSet) => expect(workoutSet, equals(set)),
      );
    });
  });
}
