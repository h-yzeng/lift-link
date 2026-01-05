import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/features/social/domain/services/workout_sharing_service.dart';

part 'workout_sharing_provider.g.dart';

/// Provider for the workout sharing service.
///
/// Use this to access sharing functionality throughout the app.
///
/// Example:
/// ```dart
/// final sharingService = ref.read(workoutSharingServiceProvider);
/// await sharingService.shareWorkoutSummary(workout);
/// ```
@Riverpod(keepAlive: true)
WorkoutSharingService workoutSharingService(Ref ref) {
  return WorkoutSharingService();
}
