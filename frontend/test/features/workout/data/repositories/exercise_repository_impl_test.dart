import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/features/workout/data/datasources/exercise_local_datasource.dart';
import 'package:liftlink/features/workout/data/datasources/exercise_remote_datasource.dart';
import 'package:liftlink/features/workout/data/repositories/exercise_repository_impl.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseLocalDataSource extends Mock
    implements ExerciseLocalDataSource {}

class MockExerciseRemoteDataSource extends Mock
    implements ExerciseRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeExercise extends Fake implements Exercise {}

void main() {
  late ExerciseRepositoryImpl repository;
  late MockExerciseLocalDataSource mockLocalDataSource;
  late MockExerciseRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUpAll(() {
    registerFallbackValue(FakeExercise());
  });

  setUp(() {
    mockLocalDataSource = MockExerciseLocalDataSource();
    mockRemoteDataSource = MockExerciseRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = ExerciseRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getAllExercises', () {
    const userId = 'test-user-id';
    final List<Exercise> testExercises = [
      Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        description: 'Chest exercise',
        muscleGroup: 'Chest',
        equipmentType: 'Barbell',
        isCustom: false,
        createdBy: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
      Exercise(
        id: 'ex-2',
        name: 'Squat',
        description: 'Leg exercise',
        muscleGroup: 'Legs',
        equipmentType: 'Barbell',
        isCustom: false,
        createdBy: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
    ];

    test('should return exercises from local datasource when available',
        () async {
      // Arrange
      when(() => mockLocalDataSource.getAllExercises(userId: userId))
          .thenAnswer((_) async => testExercises);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.getAllExercises(userId: userId);

      // Assert
      expect(result, isA<Right<Failure, List<Exercise>>>());
      result.fold(
        (failure) => fail('Should return exercises'),
        (exercises) {
          expect(exercises.length, 2);
          expect(exercises[0].name, 'Bench Press');
          expect(exercises[1].name, 'Squat');
        },
      );
      verify(() => mockLocalDataSource.getAllExercises(userId: userId))
          .called(1);
    });

    test('should sync from remote when local is empty and online', () async {
      int callCount = 0;
      // Arrange - First call returns empty, second call returns exercises
      when(() => mockLocalDataSource.getAllExercises(userId: userId))
          .thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? [] : testExercises;
      });
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.fetchAllExercises(userId: userId))
          .thenAnswer((_) async => testExercises);
      when(() => mockLocalDataSource.clearExercises())
          .thenAnswer((_) async => {});
      when(() => mockLocalDataSource.upsertExercises(any()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.getAllExercises(userId: userId);

      // Assert
      expect(result, isA<Right<Failure, List<Exercise>>>());
      result.fold(
        (failure) => fail('Should return exercises'),
        (exercises) {
          expect(exercises.length, 2);
        },
      );
      verify(() => mockRemoteDataSource.fetchAllExercises(userId: userId))
          .called(1);
      verify(() => mockLocalDataSource.clearExercises()).called(1);
      verify(() => mockLocalDataSource.upsertExercises(any())).called(1);
    });

    test('should return CacheFailure when local datasource throws', () async {
      // Arrange
      when(() => mockLocalDataSource.getAllExercises(userId: any(named: 'userId')))
          .thenThrow(const CacheException(message: 'Database error'));

      // Act
      final result = await repository.getAllExercises(userId: userId);

      // Assert
      expect(result, isA<Left<Failure, List<Exercise>>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.userMessage, 'Database error');
        },
        (exercises) => fail('Should return failure'),
      );
    });
  });

  group('getExerciseById', () {
    const exerciseId = 'ex-1';
    final testExercise = Exercise(
      id: exerciseId,
      name: 'Bench Press',
      description: 'Chest exercise',
      muscleGroup: 'Chest',
      equipmentType: 'Barbell',
      isCustom: false,
      createdBy: null,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    test('should return exercise from local datasource', () async {
      // Arrange
      when(() => mockLocalDataSource.getExerciseById(exerciseId))
          .thenAnswer((_) async => testExercise);

      // Act
      final result = await repository.getExerciseById(exerciseId);

      // Assert
      expect(result, isA<Right<Failure, Exercise>>());
      result.fold(
        (failure) => fail('Should return exercise'),
        (exercise) {
          expect(exercise.id, exerciseId);
          expect(exercise.name, 'Bench Press');
        },
      );
      verify(() => mockLocalDataSource.getExerciseById(exerciseId)).called(1);
    });

    test('should return CacheFailure when exercise not found', () async {
      // Arrange
      when(() => mockLocalDataSource.getExerciseById(any()))
          .thenThrow(const CacheException(message: 'Exercise not found'));

      // Act
      final result = await repository.getExerciseById(exerciseId);

      // Assert
      expect(result, isA<Left<Failure, Exercise>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.userMessage, 'Exercise not found');
        },
        (exercise) => fail('Should return failure'),
      );
    });
  });

  group('searchExercises', () {
    const userId = 'test-user-id';
    const query = 'bench';
    final testExercises = [
      Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        description: 'Chest exercise',
        muscleGroup: 'Chest',
        equipmentType: 'Barbell',
        isCustom: false,
        createdBy: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
      Exercise(
        id: 'ex-3',
        name: 'Incline Bench Press',
        description: 'Upper chest exercise',
        muscleGroup: 'Chest',
        equipmentType: 'Barbell',
        isCustom: false,
        createdBy: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
    ];

    test('should search exercises in local datasource', () async {
      // Arrange
      when(() => mockLocalDataSource.getAllExercises(userId: userId))
          .thenAnswer((_) async => testExercises);
      when(() => mockLocalDataSource.searchExercises(
            query: query,
            userId: userId,
          ),).thenAnswer((_) async => testExercises);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.searchExercises(
        query: query,
        userId: userId,
      );

      // Assert
      expect(result, isA<Right<Failure, List<Exercise>>>());
      result.fold(
        (failure) => fail('Should return exercises'),
        (exercises) {
          expect(exercises.length, 2);
          expect(exercises.every((e) => e.name.toLowerCase().contains('bench')),
              true,);
        },
      );
      verify(() => mockLocalDataSource.searchExercises(
            query: query,
            userId: userId,
          ),).called(1);
    });

    test('should sync from remote when local is empty and online', () async {
      // Arrange
      when(() => mockLocalDataSource.getAllExercises(userId: userId))
          .thenAnswer((_) async => []);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.fetchAllExercises(userId: userId))
          .thenAnswer((_) async => testExercises);
      when(() => mockLocalDataSource.clearExercises())
          .thenAnswer((_) async => {});
      when(() => mockLocalDataSource.upsertExercises(any()))
          .thenAnswer((_) async => {});
      when(() => mockLocalDataSource.searchExercises(
            query: query,
            userId: userId,
          ),).thenAnswer((_) async => testExercises);

      // Act
      final result = await repository.searchExercises(
        query: query,
        userId: userId,
      );

      // Assert
      expect(result, isA<Right<Failure, List<Exercise>>>());
      verify(() => mockRemoteDataSource.fetchAllExercises(userId: userId))
          .called(1);
    });

    test('should return CacheFailure when search fails', () async {
      // Arrange
      when(() => mockLocalDataSource.getAllExercises(userId: any(named: 'userId')))
          .thenThrow(const CacheException(message: 'Search failed'));

      // Act
      final result = await repository.searchExercises(
        query: query,
        userId: userId,
      );

      // Assert
      expect(result, isA<Left<Failure, List<Exercise>>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.userMessage, 'Search failed');
        },
        (exercises) => fail('Should return failure'),
      );
    });
  });

  group('getExercisesByMuscleGroup', () {
    const userId = 'test-user-id';
    const muscleGroup = 'Chest';
    final testExercises = [
      Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        description: 'Chest exercise',
        muscleGroup: 'Chest',
        equipmentType: 'Barbell',
        isCustom: false,
        createdBy: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
    ];

    test('should filter exercises by muscle group', () async {
      // Arrange
      when(() => mockLocalDataSource.getExercisesByMuscleGroup(
            muscleGroup: muscleGroup,
            userId: userId,
          ),).thenAnswer((_) async => testExercises);

      // Act
      final result = await repository.getExercisesByMuscleGroup(
        muscleGroup: muscleGroup,
        userId: userId,
      );

      // Assert
      expect(result, isA<Right<Failure, List<Exercise>>>());
      result.fold(
        (failure) => fail('Should return exercises'),
        (exercises) {
          expect(exercises.length, 1);
          expect(exercises[0].muscleGroup, 'Chest');
        },
      );
      verify(() => mockLocalDataSource.getExercisesByMuscleGroup(
            muscleGroup: muscleGroup,
            userId: userId,
          ),).called(1);
    });

    test('should return CacheFailure when filtering fails', () async {
      // Arrange
      when(() => mockLocalDataSource.getExercisesByMuscleGroup(
            muscleGroup: any(named: 'muscleGroup'),
            userId: any(named: 'userId'),
          ),).thenThrow(const CacheException(message: 'Filter failed'));

      // Act
      final result = await repository.getExercisesByMuscleGroup(
        muscleGroup: muscleGroup,
        userId: userId,
      );

      // Assert
      expect(result, isA<Left<Failure, List<Exercise>>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.userMessage, 'Filter failed');
        },
        (exercises) => fail('Should return failure'),
      );
    });
  });

  group('getExercisesByEquipment', () {
    const userId = 'test-user-id';
    const equipmentType = 'Barbell';
    final testExercises = [
      Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        description: 'Chest exercise',
        muscleGroup: 'Chest',
        equipmentType: 'Barbell',
        isCustom: false,
        createdBy: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
    ];

    test('should filter exercises by equipment type', () async {
      // Arrange
      when(() => mockLocalDataSource.getExercisesByEquipment(
            equipmentType: equipmentType,
            userId: userId,
          ),).thenAnswer((_) async => testExercises);

      // Act
      final result = await repository.getExercisesByEquipment(
        equipmentType: equipmentType,
        userId: userId,
      );

      // Assert
      expect(result, isA<Right<Failure, List<Exercise>>>());
      result.fold(
        (failure) => fail('Should return exercises'),
        (exercises) {
          expect(exercises.length, 1);
          expect(exercises[0].equipmentType, 'Barbell');
        },
      );
      verify(() => mockLocalDataSource.getExercisesByEquipment(
            equipmentType: equipmentType,
            userId: userId,
          ),).called(1);
    });

    test('should return CacheFailure when filtering fails', () async {
      // Arrange
      when(() => mockLocalDataSource.getExercisesByEquipment(
            equipmentType: any(named: 'equipmentType'),
            userId: any(named: 'userId'),
          ),).thenThrow(const CacheException(message: 'Filter failed'));

      // Act
      final result = await repository.getExercisesByEquipment(
        equipmentType: equipmentType,
        userId: userId,
      );

      // Assert
      expect(result, isA<Left<Failure, List<Exercise>>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.userMessage, 'Filter failed');
        },
        (exercises) => fail('Should return failure'),
      );
    });
  });

  group('filterExercises', () {
    const userId = 'test-user-id';
    const muscleGroup = 'Chest';
    const equipmentType = 'Barbell';
    const customOnly = false;
    final testExercises = [
      Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        description: 'Chest exercise',
        muscleGroup: 'Chest',
        equipmentType: 'Barbell',
        isCustom: false,
        createdBy: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
    ];

    test('should filter exercises with multiple criteria', () async {
      // Arrange
      when(() => mockLocalDataSource.getAllExercises(userId: userId))
          .thenAnswer((_) async => testExercises);
      when(() => mockLocalDataSource.filterExercises(
            muscleGroup: muscleGroup,
            equipmentType: equipmentType,
            customOnly: customOnly,
            userId: userId,
          ),).thenAnswer((_) async => testExercises);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.filterExercises(
        muscleGroup: muscleGroup,
        equipmentType: equipmentType,
        customOnly: customOnly,
        userId: userId,
      );

      // Assert
      expect(result, isA<Right<Failure, List<Exercise>>>());
      result.fold(
        (failure) => fail('Should return exercises'),
        (exercises) {
          expect(exercises.length, 1);
          expect(exercises[0].muscleGroup, 'Chest');
          expect(exercises[0].equipmentType, 'Barbell');
        },
      );
      verify(() => mockLocalDataSource.filterExercises(
            muscleGroup: muscleGroup,
            equipmentType: equipmentType,
            customOnly: customOnly,
            userId: userId,
          ),).called(1);
    });

    test('should sync from remote when local is empty and online', () async {
      // Arrange
      when(() => mockLocalDataSource.getAllExercises(userId: userId))
          .thenAnswer((_) async => []);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.fetchAllExercises(userId: userId))
          .thenAnswer((_) async => testExercises);
      when(() => mockLocalDataSource.clearExercises())
          .thenAnswer((_) async => {});
      when(() => mockLocalDataSource.upsertExercises(any()))
          .thenAnswer((_) async => {});
      when(() => mockLocalDataSource.filterExercises(
            muscleGroup: muscleGroup,
            equipmentType: equipmentType,
            customOnly: customOnly,
            userId: userId,
          ),).thenAnswer((_) async => testExercises);

      // Act
      final result = await repository.filterExercises(
        muscleGroup: muscleGroup,
        equipmentType: equipmentType,
        customOnly: customOnly,
        userId: userId,
      );

      // Assert
      expect(result, isA<Right<Failure, List<Exercise>>>());
      verify(() => mockRemoteDataSource.fetchAllExercises(userId: userId))
          .called(1);
    });

    test('should return CacheFailure when filtering fails', () async {
      // Arrange
      when(() => mockLocalDataSource.getAllExercises(userId: any(named: 'userId')))
          .thenThrow(const CacheException(message: 'Filter failed'));

      // Act
      final result = await repository.filterExercises(
        muscleGroup: muscleGroup,
        userId: userId,
      );

      // Assert
      expect(result, isA<Left<Failure, List<Exercise>>>());
      result.fold(
        (failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.userMessage, 'Filter failed');
        },
        (exercises) => fail('Should return failure'),
      );
    });
  });

  group('createCustomExercise', () {
    const userId = 'test-user-id';
    const name = 'Custom Exercise';
    const description = 'My custom exercise';
    const muscleGroup = 'Chest';
    const equipmentType = 'Dumbbell';
    final testExercise = Exercise(
      id: 'custom-ex-1',
      name: name,
      description: description,
      muscleGroup: muscleGroup,
      equipmentType: equipmentType,
      isCustom: true,
      createdBy: userId,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    test('should create custom exercise remotely and save locally', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.createCustomExercise(
            id: any(named: 'id'),
            name: name,
            description: description,
            muscleGroup: muscleGroup,
            equipmentType: equipmentType,
            userId: userId,
          ),).thenAnswer((_) async => testExercise);
      when(() => mockLocalDataSource.upsertExercise(any()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.createCustomExercise(
        name: name,
        description: description,
        muscleGroup: muscleGroup,
        equipmentType: equipmentType,
        userId: userId,
      );

      // Assert
      expect(result, isA<Right<Failure, Exercise>>());
      result.fold(
        (failure) => fail('Should return exercise'),
        (exercise) {
          expect(exercise.name, name);
          expect(exercise.isCustom, true);
        },
      );
      verify(() => mockRemoteDataSource.createCustomExercise(
            id: any(named: 'id'),
            name: name,
            description: description,
            muscleGroup: muscleGroup,
            equipmentType: equipmentType,
            userId: userId,
          ),).called(1);
      verify(() => mockLocalDataSource.upsertExercise(testExercise)).called(1);
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.createCustomExercise(
        name: name,
        description: description,
        muscleGroup: muscleGroup,
        equipmentType: equipmentType,
        userId: userId,
      );

      // Assert
      expect(result, isA<Left<Failure, Exercise>>());
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.userMessage, 'No internet connection');
        },
        (exercise) => fail('Should return failure'),
      );
      verifyNever(() => mockRemoteDataSource.createCustomExercise(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            muscleGroup: any(named: 'muscleGroup'),
            equipmentType: any(named: 'equipmentType'),
            userId: any(named: 'userId'),
          ),);
    });

    test('should return ServerFailure when creation fails', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.createCustomExercise(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            muscleGroup: any(named: 'muscleGroup'),
            equipmentType: any(named: 'equipmentType'),
            userId: any(named: 'userId'),
          ),).thenThrow(const ServerException(message: 'Creation failed'));

      // Act
      final result = await repository.createCustomExercise(
        name: name,
        description: description,
        muscleGroup: muscleGroup,
        equipmentType: equipmentType,
        userId: userId,
      );

      // Assert
      expect(result, isA<Left<Failure, Exercise>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.userMessage, 'Creation failed');
        },
        (exercise) => fail('Should return failure'),
      );
    });
  });

  group('updateCustomExercise', () {
    const exerciseId = 'custom-ex-1';
    const name = 'Updated Exercise';
    final updatedExercise = Exercise(
      id: exerciseId,
      name: name,
      description: 'Updated description',
      muscleGroup: 'Chest',
      equipmentType: 'Dumbbell',
      isCustom: true,
      createdBy: 'test-user-id',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 2),
    );

    test('should update custom exercise remotely and save locally', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.updateCustomExercise(
            id: exerciseId,
            name: name,
            description: any(named: 'description'),
            muscleGroup: any(named: 'muscleGroup'),
            equipmentType: any(named: 'equipmentType'),
          ),).thenAnswer((_) async => updatedExercise);
      when(() => mockLocalDataSource.upsertExercise(any()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.updateCustomExercise(
        id: exerciseId,
        name: name,
      );

      // Assert
      expect(result, isA<Right<Failure, Exercise>>());
      result.fold(
        (failure) => fail('Should return exercise'),
        (exercise) {
          expect(exercise.id, exerciseId);
          expect(exercise.name, name);
        },
      );
      verify(() => mockRemoteDataSource.updateCustomExercise(
            id: exerciseId,
            name: name,
            description: any(named: 'description'),
            muscleGroup: any(named: 'muscleGroup'),
            equipmentType: any(named: 'equipmentType'),
          ),).called(1);
      verify(() => mockLocalDataSource.upsertExercise(updatedExercise))
          .called(1);
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.updateCustomExercise(
        id: exerciseId,
        name: name,
      );

      // Assert
      expect(result, isA<Left<Failure, Exercise>>());
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.userMessage, 'No internet connection');
        },
        (exercise) => fail('Should return failure'),
      );
    });

    test('should return ServerFailure when update fails', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.updateCustomExercise(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            muscleGroup: any(named: 'muscleGroup'),
            equipmentType: any(named: 'equipmentType'),
          ),).thenThrow(const ServerException(message: 'Update failed'));

      // Act
      final result = await repository.updateCustomExercise(
        id: exerciseId,
        name: name,
      );

      // Assert
      expect(result, isA<Left<Failure, Exercise>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.userMessage, 'Update failed');
        },
        (exercise) => fail('Should return failure'),
      );
    });
  });

  group('deleteCustomExercise', () {
    const exerciseId = 'custom-ex-1';

    test('should delete custom exercise remotely and locally', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.deleteCustomExercise(exerciseId))
          .thenAnswer((_) async => {});
      when(() => mockLocalDataSource.deleteExercise(exerciseId))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.deleteCustomExercise(exerciseId);

      // Assert
      expect(result, isA<Right<Failure, void>>());
      verify(() => mockRemoteDataSource.deleteCustomExercise(exerciseId))
          .called(1);
      verify(() => mockLocalDataSource.deleteExercise(exerciseId)).called(1);
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.deleteCustomExercise(exerciseId);

      // Assert
      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.userMessage, 'No internet connection');
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return ServerFailure when deletion fails', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.deleteCustomExercise(any()))
          .thenThrow(const ServerException(message: 'Deletion failed'));

      // Act
      final result = await repository.deleteCustomExercise(exerciseId);

      // Assert
      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.userMessage, 'Deletion failed');
        },
        (_) => fail('Should return failure'),
      );
    });
  });

  group('syncExercises', () {
    const userId = 'test-user-id';
    final testExercises = [
      Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        description: 'Chest exercise',
        muscleGroup: 'Chest',
        equipmentType: 'Barbell',
        isCustom: false,
        createdBy: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
    ];

    test('should fetch from remote and save to local', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.fetchAllExercises(userId: userId))
          .thenAnswer((_) async => testExercises);
      when(() => mockLocalDataSource.clearExercises())
          .thenAnswer((_) async => {});
      when(() => mockLocalDataSource.upsertExercises(any()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.syncExercises(userId: userId);

      // Assert
      expect(result, isA<Right<Failure, void>>());
      verify(() => mockRemoteDataSource.fetchAllExercises(userId: userId))
          .called(1);
      verify(() => mockLocalDataSource.clearExercises()).called(1);
      verify(() => mockLocalDataSource.upsertExercises(testExercises))
          .called(1);
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.syncExercises(userId: userId);

      // Assert
      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.userMessage, 'No internet connection');
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return ServerFailure when sync fails', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.fetchAllExercises(userId: any(named: 'userId')))
          .thenThrow(const ServerException(message: 'Sync failed'));

      // Act
      final result = await repository.syncExercises(userId: userId);

      // Assert
      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.userMessage, 'Sync failed');
        },
        (_) => fail('Should return failure'),
      );
    });
  });
}
