import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/core/network/network_info.dart';
import 'package:liftlink/features/workout/data/datasources/exercise_local_datasource.dart';
import 'package:liftlink/features/workout/data/datasources/exercise_remote_datasource.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/domain/repositories/exercise_repository.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseLocalDataSource localDataSource;
  final ExerciseRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ExerciseRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Exercise>>> getAllExercises({
    String? userId,
  }) async {
    try {
      // Always read from local (offline-first)
      final exercises = await localDataSource.getAllExercises(userId: userId);

      // If local is empty and we're online, perform initial sync and wait
      if (exercises.isEmpty && await networkInfo.isConnected) {
        final syncResult = await syncExercises(userId: userId);

        // If sync succeeded, read fresh data from local
        if (syncResult.isRight()) {
          final freshExercises = await localDataSource.getAllExercises(userId: userId);
          return Right(freshExercises);
        }
        // Sync failed, return empty list
        return Right(exercises);
      }

      // Sync in background if we have data
      if (await networkInfo.isConnected) {
        _syncInBackground(userId: userId);
      }

      return Right(exercises);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Exercise>> getExerciseById(String id) async {
    try {
      final exercise = await localDataSource.getExerciseById(id);
      return Right(exercise);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Exercise>>> searchExercises({
    required String query,
    String? userId,
  }) async {
    try {
      // First check if local database has any exercises at all
      final allExercises = await localDataSource.getAllExercises(userId: userId);

      // If local is empty and we're online, perform initial sync and wait
      if (allExercises.isEmpty && await networkInfo.isConnected) {
        final syncResult = await syncExercises(userId: userId);

        // After sync, perform the search
        if (syncResult.isRight()) {
          final exercises = await localDataSource.searchExercises(
            query: query,
            userId: userId,
          );
          return Right(exercises);
        }
        // Sync failed, return empty list
        return const Right([]);
      }

      // Perform search on existing data
      final exercises = await localDataSource.searchExercises(
        query: query,
        userId: userId,
      );

      // Sync in background if we have data
      if (allExercises.isNotEmpty && await networkInfo.isConnected) {
        _syncInBackground(userId: userId);
      }

      return Right(exercises);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Exercise>>> getExercisesByMuscleGroup({
    required String muscleGroup,
    String? userId,
  }) async {
    try {
      final exercises = await localDataSource.getExercisesByMuscleGroup(
        muscleGroup: muscleGroup,
        userId: userId,
      );
      return Right(exercises);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Exercise>>> getExercisesByEquipment({
    required String equipmentType,
    String? userId,
  }) async {
    try {
      final exercises = await localDataSource.getExercisesByEquipment(
        equipmentType: equipmentType,
        userId: userId,
      );
      return Right(exercises);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Exercise>>> filterExercises({
    String? muscleGroup,
    String? equipmentType,
    bool? customOnly,
    String? userId,
  }) async {
    try {
      // First check if we have ANY exercises in the local database
      final allExercises = await localDataSource.getAllExercises(userId: userId);

      // If local database is completely empty and we're online, perform initial sync
      if (allExercises.isEmpty && await networkInfo.isConnected) {
        final syncResult = await syncExercises(userId: userId);

        // If sync succeeded, get filtered results
        if (syncResult.isRight()) {
          final exercises = await localDataSource.filterExercises(
            muscleGroup: muscleGroup,
            equipmentType: equipmentType,
            customOnly: customOnly,
            userId: userId,
          );
          return Right(exercises);
        }
        // Sync failed, return empty list
        return const Right([]);
      }

      // Get filtered exercises from local database
      final exercises = await localDataSource.filterExercises(
        muscleGroup: muscleGroup,
        equipmentType: equipmentType,
        customOnly: customOnly,
        userId: userId,
      );

      // Sync in background if we have data
      if (allExercises.isNotEmpty && await networkInfo.isConnected) {
        _syncInBackground(userId: userId);
      }

      return Right(exercises);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Exercise>> createCustomExercise({
    required String name,
    String? description,
    required String muscleGroup,
    String? equipmentType,
    required String userId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      final id = const Uuid().v4();
      final exercise = await remoteDataSource.createCustomExercise(
        id: id,
        name: name,
        description: description,
        muscleGroup: muscleGroup,
        equipmentType: equipmentType,
        userId: userId,
      );

      // Save to local
      await localDataSource.upsertExercise(exercise);

      return Right(exercise);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Exercise>> updateCustomExercise({
    required String id,
    String? name,
    String? description,
    String? muscleGroup,
    String? equipmentType,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      final exercise = await remoteDataSource.updateCustomExercise(
        id: id,
        name: name,
        description: description,
        muscleGroup: muscleGroup,
        equipmentType: equipmentType,
      );

      // Update local
      await localDataSource.upsertExercise(exercise);

      return Right(exercise);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomExercise(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      await remoteDataSource.deleteCustomExercise(id);
      await localDataSource.deleteExercise(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncExercises({String? userId}) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      final exercises = await remoteDataSource.fetchAllExercises(
        userId: userId,
      );

      // Clear existing exercises before syncing to prevent duplicates
      await localDataSource.clearExercises();
      await localDataSource.upsertExercises(exercises);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Sync exercises in the background (fire and forget)
  void _syncInBackground({String? userId}) {
    syncExercises(userId: userId);
  }
}
