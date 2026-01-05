import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auto_start_rest_timer_preference.g.dart';

const _autoStartRestTimerKey = 'auto_start_rest_timer';
const _defaultAutoStart = false;

/// Provider for auto-start rest timer setting.
@Riverpod(keepAlive: true)
class AutoStartRestTimerNotifier extends _$AutoStartRestTimerNotifier {
  @override
  bool build() {
    _loadValue();
    return _defaultAutoStart;
  }

  Future<void> _loadValue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_autoStartRestTimerKey);
      if (value != null) {
        state = value;
      }
    } catch (e) {
      // Use default if loading fails
    }
  }

  Future<void> toggle() async {
    state = !state;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoStartRestTimerKey, state);
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<void> setValue(bool value) async {
    state = value;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoStartRestTimerKey, value);
    } catch (e) {
      // Ignore save errors
    }
  }
}
