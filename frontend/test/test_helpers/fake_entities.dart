import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/domain/entities/exercise_performance.dart';
import 'package:liftlink/features/workout/domain/entities/set_performance.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';

/// Fake entities for testing
class FakeEntities {
  /// Create a fake workout session
  static WorkoutSession workoutSession({
    String id = 'workout1',
    String userId = 'user1',
    String title = 'Test Workout',
    DateTime? startedAt,
    DateTime? completedAt,
    List<ExercisePerformance> exercises = const [],
    String? notes,
  }) {
    final now = DateTime.now();
    return WorkoutSession(
      id: id,
      userId: userId,
      title: title,
      startedAt: startedAt ?? now.subtract(const Duration(hours: 1)),
      completedAt: completedAt,
      exercises: exercises,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a fake exercise performance
  static ExercisePerformance exercisePerformance({
    String id = 'exercise1',
    String workoutSessionId = 'workout1',
    String exerciseId = 'bench-press',
    String exerciseName = 'Bench Press',
    List<SetPerformance> sets = const [],
    double? maxWeight,
  }) {
    final now = DateTime.now();
    return ExercisePerformance(
      id: id,
      workoutSessionId: workoutSessionId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets,
      maxWeight: maxWeight,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a fake set performance
  static SetPerformance setPerformance({
    String id = 'set1',
    String exercisePerformanceId = 'exercise1',
    int setNumber = 1,
    int reps = 10,
    double weightKg = 60.0,
    bool isWarmup = false,
    double? rpe,
    int? rir,
  }) {
    final now = DateTime.now();
    return SetPerformance(
      id: id,
      exercisePerformanceId: exercisePerformanceId,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      isWarmup: isWarmup,
      rpe: rpe,
      rir: rir,
      completedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a fake profile
  static Profile profile({
    String id = 'user1',
    String? displayName,
    String? avatarUrl,
    String? bio,
    String preferredUnits = 'imperial',
  }) {
    final now = DateTime.now();
    return Profile(
      id: id,
      displayName: displayName ?? 'Test User',
      avatarUrl: avatarUrl,
      bio: bio,
      preferredUnits: preferredUnits,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a fake friendship
  static Friendship friendship({
    String id = 'friendship1',
    String requesterId = 'user1',
    String addresseeId = 'user2',
    FriendshipStatus status = FriendshipStatus.accepted,
    String? nickname,
  }) {
    final now = DateTime.now();
    return Friendship(
      id: id,
      requesterId: requesterId,
      addresseeId: addresseeId,
      status: status,
      nickname: nickname,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a complete workout with exercises and sets
  static WorkoutSession completeWorkout() {
    final sets = [
      setPerformance(id: 'set1', setNumber: 1, reps: 10, weightKg: 60.0),
      setPerformance(id: 'set2', setNumber: 2, reps: 8, weightKg: 65.0),
      setPerformance(id: 'set3', setNumber: 3, reps: 6, weightKg: 70.0),
    ];

    final exercises = [
      exercisePerformance(
        id: 'ex1',
        exerciseId: 'bench-press',
        exerciseName: 'Bench Press',
        sets: sets,
        maxWeight: 70.0,
      ),
      exercisePerformance(
        id: 'ex2',
        exerciseId: 'squat',
        exerciseName: 'Squat',
        sets: sets.map((s) => s.copyWith(id: '${s.id}_squat')).toList(),
        maxWeight: 100.0,
      ),
    ];

    return workoutSession(
      title: 'Push Day',
      exercises: exercises,
      completedAt: DateTime.now(),
    );
  }
}
