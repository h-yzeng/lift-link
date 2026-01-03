import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _autoStartRestTimerKey = 'auto_start_rest_timer';
const _defaultAutoStart = false;

/// Provider for auto-start rest timer setting.
final autoStartRestTimerProvider =
    StateNotifierProvider<AutoStartRestTimerNotifier, bool>((ref) {
  return AutoStartRestTimerNotifier();
});

/// Notifier for managing auto-start rest timer preference.
class AutoStartRestTimerNotifier extends StateNotifier<bool> {
  AutoStartRestTimerNotifier() : super(_defaultAutoStart) {
    _loadValue();
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
