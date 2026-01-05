import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'rest_timer_preference.g.dart';

const _restTimerKey = 'default_rest_timer_seconds';
const _defaultRestSeconds = 90;

/// Provider for default rest timer duration in seconds.
@Riverpod(keepAlive: true)
class DefaultRestTimerNotifier extends _$DefaultRestTimerNotifier {
  @override
  int build() {
    _loadValue();
    return _defaultRestSeconds;
  }

  Future<void> _loadValue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_restTimerKey);
      if (value != null) {
        state = value;
      }
    } catch (e) {
      // Use default if loading fails
    }
  }

  Future<void> setDuration(int seconds) async {
    if (seconds < 15 || seconds > 600) return; // 15 seconds to 10 minutes

    state = seconds;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_restTimerKey, seconds);
    } catch (e) {
      // Ignore save errors
    }
  }
}

/// Legacy provider for backward compatibility
final defaultRestTimerSecondsProvider = defaultRestTimerProvider;

/// Common rest timer presets.
class RestTimerPresets {
  static const List<int> values = [30, 60, 90, 120, 180, 300];

  static String formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds % 60 == 0) {
      return '${seconds ~/ 60}m';
    } else {
      return '${seconds ~/ 60}m ${seconds % 60}s';
    }
  }
}
