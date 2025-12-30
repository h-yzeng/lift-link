import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/data/models/exercise_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Remote data source for exercises using Supabase
abstract class ExerciseRemoteDataSource {
  /// Fetch all exercises from Supabase
  Future<List<Exercise>> fetchAllExercises({String? userId});

  /// Fetch exercise by ID
  Future<Exercise> fetchExerciseById(String id);

  /// Create custom exercise
  Future<Exercise> createCustomExercise({
    required String id,
    required String name,
    String? description,
    required String muscleGroup,
    String? equipmentType,
    required String userId,
  });

  /// Update custom exercise
  Future<Exercise> updateCustomExercise({
    required String id,
    String? name,
    String? description,
    String? muscleGroup,
    String? equipmentType,
  });

  /// Delete custom exercise
  Future<void> deleteCustomExercise(String id);
}

class ExerciseRemoteDataSourceImpl implements ExerciseRemoteDataSource {
  final supabase.SupabaseClient supabaseClient;

  ExerciseRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<Exercise>> fetchAllExercises({String? userId}) async {
    try {
      // Build query properly with method chaining
      final response = userId != null
          ? await supabaseClient
              .from('exercises')
              .select()
              .or('is_custom.eq.false,created_by.eq.$userId')
              .order('muscle_group')
              .order('name')
          : await supabaseClient
              .from('exercises')
              .select()
              .eq('is_custom', false)
              .order('muscle_group')
              .order('name');

      return (response as List<dynamic>)
          .map((json) => exerciseFromJson(json as Map<String, dynamic>))
          .toList();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Exercise> fetchExerciseById(String id) async {
    try {
      final response = await supabaseClient
          .from('exercises')
          .select()
          .eq('id', id)
          .single();

      return exerciseFromJson(response);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Exercise> createCustomExercise({
    required String id,
    required String name,
    String? description,
    required String muscleGroup,
    String? equipmentType,
    required String userId,
  }) async {
    try {
      final now = DateTime.now();
      final exercise = Exercise(
        id: id,
        name: name,
        description: description,
        muscleGroup: muscleGroup,
        equipmentType: equipmentType,
        isCustom: true,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );

      final response = await supabaseClient
          .from('exercises')
          .insert(exerciseToJson(exercise))
          .select()
          .single();

      return exerciseFromJson(response);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Exercise> updateCustomExercise({
    required String id,
    String? name,
    String? description,
    String? muscleGroup,
    String? equipmentType,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (muscleGroup != null) updates['muscle_group'] = muscleGroup;
      if (equipmentType != null) updates['equipment_type'] = equipmentType;

      final response = await supabaseClient
          .from('exercises')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return exerciseFromJson(response);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteCustomExercise(String id) async {
    try {
      await supabaseClient.from('exercises').delete().eq('id', id);
    } on supabase.PostgrestException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
