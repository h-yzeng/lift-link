import 'package:dartz/dartz.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';

/// Repository interface for exercise operations
abstract class ExerciseRepository {
  /// Get all exercises (system + user's custom exercises)
  Future<Either<Failure, List<Exercise>>> getAllExercises({
    String? userId,
  });

  /// Get exercise by ID
  Future<Either<Failure, Exercise>> getExerciseById(String id);

  /// Search exercises by name
  Future<Either<Failure, List<Exercise>>> searchExercises({
    required String query,
    String? userId,
  });

  /// Filter exercises by muscle group
  Future<Either<Failure, List<Exercise>>> getExercisesByMuscleGroup({
    required String muscleGroup,
    String? userId,
  });

  /// Filter exercises by equipment type
  Future<Either<Failure, List<Exercise>>> getExercisesByEquipment({
    required String equipmentType,
    String? userId,
  });

  /// Filter exercises with multiple criteria
  Future<Either<Failure, List<Exercise>>> filterExercises({
    String? muscleGroup,
    String? equipmentType,
    bool? customOnly,
    String? userId,
  });

  /// Create a custom exercise
  Future<Either<Failure, Exercise>> createCustomExercise({
    required String name,
    String? description,
    required String muscleGroup,
    String? equipmentType,
    required String userId,
  });

  /// Update a custom exercise
  Future<Either<Failure, Exercise>> updateCustomExercise({
    required String id,
    String? name,
    String? description,
    String? muscleGroup,
    String? equipmentType,
  });

  /// Delete a custom exercise
  Future<Either<Failure, void>> deleteCustomExercise(String id);

  /// Sync exercises from remote to local
  Future<Either<Failure, void>> syncExercises({String? userId});
}
