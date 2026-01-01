import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/repositories/workout_repository.dart';
import 'package:liftlink/features/workout/domain/usecases/start_workout.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  late StartWorkout useCase;
  late MockWorkoutRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkoutRepository();
    useCase = StartWorkout(mockRepository);
  });

  WorkoutSession createSession() {
    return WorkoutSession(
      id: 'session-id',
      userId: 'user-id',
      title: 'Test Workout',
      startedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('StartWorkout', () {
    test('returns ValidationFailure when userId is empty', () async {
      final result = await useCase(
        userId: '',
        title: 'Test Workout',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns ValidationFailure when userId is whitespace', () async {
      final result = await useCase(
        userId: '   ',
        title: 'Test Workout',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('User ID'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('returns ValidationFailure when title is empty', () async {
      final result = await useCase(
        userId: 'user-id',
        title: '',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('title'));
        },
        (_) => fail('Should return failure'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns ValidationFailure when title is whitespace', () async {
      final result = await useCase(
        userId: 'user-id',
        title: '   ',
      );

      expect(result.isLeft(), isTrue);
    });

    test('calls repository with correct parameters', () async {
      final session = createSession();
      when(
        () => mockRepository.startWorkout(
          userId: any(named: 'userId'),
          title: any(named: 'title'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => Right(session));

      await useCase(
        userId: 'user-123',
        title: 'Morning Workout',
        notes: 'Feeling good',
      );

      verify(
        () => mockRepository.startWorkout(
          userId: 'user-123',
          title: 'Morning Workout',
          notes: 'Feeling good',
        ),
      ).called(1);
    });

    test('returns WorkoutSession on success', () async {
      final session = createSession();
      when(
        () => mockRepository.startWorkout(
          userId: any(named: 'userId'),
          title: any(named: 'title'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => Right(session));

      final result = await useCase(
        userId: 'user-id',
        title: 'Test Workout',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return success'),
        (workout) => expect(workout, equals(session)),
      );
    });

    test('returns failure from repository on error', () async {
      when(
        () => mockRepository.startWorkout(
          userId: any(named: 'userId'),
          title: any(named: 'title'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Network error')),
      );

      final result = await useCase(
        userId: 'user-id',
        title: 'Test Workout',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });
}
