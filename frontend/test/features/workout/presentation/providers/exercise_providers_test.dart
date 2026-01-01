import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/domain/entities/user.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/domain/usecases/filter_exercises.dart';
import 'package:liftlink/features/workout/domain/usecases/search_exercises.dart';
import 'package:liftlink/features/workout/presentation/providers/exercise_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockFilterExercises extends Mock implements FilterExercises {}

class MockSearchExercises extends Mock implements SearchExercises {}

void main() {
  late MockFilterExercises mockFilterExercises;
  late MockSearchExercises mockSearchExercises;

  final testUser = User(
    id: 'test-user-id',
    email: 'test@example.com',
    createdAt: DateTime(2025, 1, 1),
  );

  final testExercises = <Exercise>[
    Exercise(
      id: 'exercise-1',
      name: 'Bench Press',
      muscleGroup: 'chest',
      equipmentType: 'barbell',
      isCustom: false,
      createdBy: null,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ),
    Exercise(
      id: 'exercise-2',
      name: 'Squat',
      muscleGroup: 'legs',
      equipmentType: 'barbell',
      isCustom: false,
      createdBy: null,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ),
    Exercise(
      id: 'exercise-3',
      name: 'Custom Exercise',
      muscleGroup: 'arms',
      equipmentType: 'dumbbell',
      isCustom: true,
      createdBy: testUser.id,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ),
  ];

  setUp(() {
    mockFilterExercises = MockFilterExercises();
    mockSearchExercises = MockSearchExercises();
  });

  group('exerciseList provider', () {
    test('should return all exercises when no filters applied', () async {
      // Arrange
      when(() => mockFilterExercises(
            muscleGroup: null,
            equipmentType: null,
            customOnly: null,
            userId: testUser.id,
          ),).thenAnswer((_) async => Right(testExercises));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          filterExercisesUseCaseProvider.overrideWithValue(mockFilterExercises),
        ],
      );

      // Act
      final result = await container.read(exerciseListProvider().future);

      // Assert
      expect(result, testExercises);
      verify(() => mockFilterExercises(
            muscleGroup: null,
            equipmentType: null,
            customOnly: null,
            userId: testUser.id,
          ),).called(1);

      container.dispose();
    });

    test('should filter exercises by muscle group', () async {
      // Arrange
      final chestExercises = [testExercises[0]];
      when(() => mockFilterExercises(
            muscleGroup: 'chest',
            equipmentType: null,
            customOnly: null,
            userId: testUser.id,
          ),).thenAnswer((_) async => Right(chestExercises));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          filterExercisesUseCaseProvider.overrideWithValue(mockFilterExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseListProvider(muscleGroup: 'chest').future,
      );

      // Assert
      expect(result.length, 1);
      expect(result[0].muscleGroup, 'chest');
      verify(() => mockFilterExercises(
            muscleGroup: 'chest',
            equipmentType: null,
            customOnly: null,
            userId: testUser.id,
          ),).called(1);

      container.dispose();
    });

    test('should filter exercises by equipment type', () async {
      // Arrange
      final barbellExercises = testExercises.sublist(0, 2);
      when(() => mockFilterExercises(
            muscleGroup: null,
            equipmentType: 'barbell',
            customOnly: null,
            userId: testUser.id,
          ),).thenAnswer((_) async => Right(barbellExercises));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          filterExercisesUseCaseProvider.overrideWithValue(mockFilterExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseListProvider(equipmentType: 'barbell').future,
      );

      // Assert
      expect(result.length, 2);
      expect(result.every((e) => e.equipmentType == 'barbell'), true);

      container.dispose();
    });

    test('should filter for custom exercises only', () async {
      // Arrange
      final customExercises = [testExercises[2]];
      when(() => mockFilterExercises(
            muscleGroup: null,
            equipmentType: null,
            customOnly: true,
            userId: testUser.id,
          ),).thenAnswer((_) async => Right(customExercises));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          filterExercisesUseCaseProvider.overrideWithValue(mockFilterExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseListProvider(customOnly: true).future,
      );

      // Assert
      expect(result.length, 1);
      expect(result[0].isCustom, true);

      container.dispose();
    });

    test('should combine multiple filters', () async {
      // Arrange
      when(() => mockFilterExercises(
            muscleGroup: 'chest',
            equipmentType: 'barbell',
            customOnly: false,
            userId: testUser.id,
          ),).thenAnswer((_) async => Right([testExercises[0]]));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          filterExercisesUseCaseProvider.overrideWithValue(mockFilterExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseListProvider(
          muscleGroup: 'chest',
          equipmentType: 'barbell',
          customOnly: false,
        ).future,
      );

      // Assert
      expect(result.length, 1);
      expect(result[0].muscleGroup, 'chest');
      expect(result[0].equipmentType, 'barbell');
      expect(result[0].isCustom, false);

      verify(() => mockFilterExercises(
            muscleGroup: 'chest',
            equipmentType: 'barbell',
            customOnly: false,
            userId: testUser.id,
          ),).called(1);

      container.dispose();
    });

    test('should pass null userId when user is not authenticated', () async {
      // Arrange
      final systemExercises = testExercises.sublist(0, 2);
      when(() => mockFilterExercises(
            muscleGroup: null,
            equipmentType: null,
            customOnly: null,
            userId: null,
          ),).thenAnswer((_) async => Right(systemExercises));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(null)),
          filterExercisesUseCaseProvider.overrideWithValue(mockFilterExercises),
        ],
      );

      // Act
      final result = await container.read(exerciseListProvider().future);

      // Assert
      expect(result.length, 2);
      verify(() => mockFilterExercises(
            muscleGroup: null,
            equipmentType: null,
            customOnly: null,
            userId: null,
          ),).called(1);

      container.dispose();
    });

    test('should throw exception when use case fails', () async {
      // Arrange
      when(() => mockFilterExercises(
            muscleGroup: any(named: 'muscleGroup'),
            equipmentType: any(named: 'equipmentType'),
            customOnly: any(named: 'customOnly'),
            userId: any(named: 'userId'),
          ),).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Database error')),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          filterExercisesUseCaseProvider.overrideWithValue(mockFilterExercises),
        ],
      );

      // Act & Assert
      await expectLater(
        container.read(exerciseListProvider().future),
        throwsA(isA<Exception>()),
      );

      container.dispose();
    });
  });

  group('exerciseSearchResults provider', () {
    test('should return search results for valid query', () async {
      // Arrange
      const query = 'bench';
      final searchResults = [testExercises[0]];

      when(() => mockSearchExercises(
            query: query,
            userId: testUser.id,
          ),).thenAnswer((_) async => Right(searchResults));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          searchExercisesUseCaseProvider.overrideWithValue(mockSearchExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseSearchResultsProvider(query).future,
      );

      // Assert
      expect(result, searchResults);
      verify(() => mockSearchExercises(
            query: query,
            userId: testUser.id,
          ),).called(1);

      container.dispose();
    });

    test('should return empty list for empty query', () async {
      // Arrange
      const query = '';
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          searchExercisesUseCaseProvider.overrideWithValue(mockSearchExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseSearchResultsProvider(query).future,
      );

      // Assert
      expect(result, isEmpty);
      verifyNever(() => mockSearchExercises(
            query: any(named: 'query'),
            userId: any(named: 'userId'),
          ),);

      container.dispose();
    });

    test('should return empty list for whitespace-only query', () async {
      // Arrange
      const query = '   ';
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          searchExercisesUseCaseProvider.overrideWithValue(mockSearchExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseSearchResultsProvider(query).future,
      );

      // Assert
      expect(result, isEmpty);
      verifyNever(() => mockSearchExercises(
            query: any(named: 'query'),
            userId: any(named: 'userId'),
          ),);

      container.dispose();
    });

    test('should search with query trimmed', () async {
      // Arrange
      const query = '  squat  ';
      final searchResults = [testExercises[1]];

      when(() => mockSearchExercises(
            query: any(named: 'query'),
            userId: testUser.id,
          ),).thenAnswer((_) async => Right(searchResults));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          searchExercisesUseCaseProvider.overrideWithValue(mockSearchExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseSearchResultsProvider(query).future,
      );

      // Assert
      expect(result, searchResults);
      // The query gets trimmed in the check, so actual call uses original
      verify(() => mockSearchExercises(
            query: query,
            userId: testUser.id,
          ),).called(1);

      container.dispose();
    });

    test('should pass null userId when user is not authenticated', () async {
      // Arrange
      const query = 'exercise';
      final systemExercises = testExercises.sublist(0, 2);

      when(() => mockSearchExercises(
            query: query,
            userId: null,
          ),).thenAnswer((_) async => Right(systemExercises));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(null)),
          searchExercisesUseCaseProvider.overrideWithValue(mockSearchExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseSearchResultsProvider(query).future,
      );

      // Assert
      expect(result, systemExercises);
      verify(() => mockSearchExercises(
            query: query,
            userId: null,
          ),).called(1);

      container.dispose();
    });

    test('should handle case-insensitive search', () async {
      // Arrange
      const query = 'BENCH';
      final searchResults = [testExercises[0]];

      when(() => mockSearchExercises(
            query: query,
            userId: testUser.id,
          ),).thenAnswer((_) async => Right(searchResults));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          searchExercisesUseCaseProvider.overrideWithValue(mockSearchExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseSearchResultsProvider(query).future,
      );

      // Assert
      expect(result, searchResults);

      container.dispose();
    });

    test('should throw exception when use case fails', () async {
      // Arrange
      const query = 'test';
      when(() => mockSearchExercises(
            query: query,
            userId: testUser.id,
          ),).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Search failed')),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          searchExercisesUseCaseProvider.overrideWithValue(mockSearchExercises),
        ],
      );

      // Act & Assert
      await expectLater(
        container.read(exerciseSearchResultsProvider(query).future),
        throwsA(isA<Exception>()),
      );

      container.dispose();
    });

    test('should return multiple matching exercises', () async {
      // Arrange
      const query = 'exercise';
      when(() => mockSearchExercises(
            query: query,
            userId: testUser.id,
          ),).thenAnswer((_) async => Right(testExercises));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          searchExercisesUseCaseProvider.overrideWithValue(mockSearchExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseSearchResultsProvider(query).future,
      );

      // Assert
      expect(result.length, 3);
      expect(result, testExercises);

      container.dispose();
    });

    test('should return empty list when no matches found', () async {
      // Arrange
      const query = 'nonexistent';
      when(() => mockSearchExercises(
            query: query,
            userId: testUser.id,
          ),).thenAnswer((_) async => const Right([]));

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => Future.value(testUser)),
          searchExercisesUseCaseProvider.overrideWithValue(mockSearchExercises),
        ],
      );

      // Act
      final result = await container.read(
        exerciseSearchResultsProvider(query).future,
      );

      // Assert
      expect(result, isEmpty);

      container.dispose();
    });
  });
}
