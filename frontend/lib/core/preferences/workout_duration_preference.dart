import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'workout_duration_preference.g.dart';

const _targetDurationKey = 'target_workout_duration_minutes';
const _defaultTargetMinutes = 60; // 1 hour default

/// Provider for target workout duration in minutes.
@Riverpod(keepAlive: true)
class TargetWorkoutDurationNotifier extends _$TargetWorkoutDurationNotifier {
  @override
  int build() {
    _loadValue();
    return _defaultTargetMinutes;
  }

  Future<void> _loadValue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_targetDurationKey);
      if (value != null) {
        state = value;
      }
    } catch (e) {
      // Use default if loading fails
    }
  }

  Future<void> setDuration(int minutes) async {
    if (minutes < 15 || minutes > 300) return; // 15 min to 5 hours

    state = minutes;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_targetDurationKey, minutes);
    } catch (e) {
      // Ignore save errors
    }
  }
}

/// Common workout duration presets.
class WorkoutDurationPresets {
  static const List<int> values = [30, 45, 60, 75, 90, 120];

  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return '${hours}h';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }
}
