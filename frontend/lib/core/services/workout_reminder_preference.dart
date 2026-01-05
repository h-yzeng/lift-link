import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liftlink/core/services/notification_service.dart';

const _reminderEnabledKey = 'workout_reminder_enabled';
const _reminderHourKey = 'workout_reminder_hour';
const _reminderMinuteKey = 'workout_reminder_minute';

/// Provider for workout reminder preferences
final workoutReminderProvider = StateNotifierProvider<WorkoutReminderNotifier, WorkoutReminderState>((ref) {
  return WorkoutReminderNotifier();
});

class WorkoutReminderState {
  final bool enabled;
  final int hour;
  final int minute;

  WorkoutReminderState({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  WorkoutReminderState copyWith({
    bool? enabled,
    int? hour,
    int? minute,
  }) {
    return WorkoutReminderState(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class WorkoutReminderNotifier extends StateNotifier<WorkoutReminderState> {
  WorkoutReminderNotifier()
      : super(WorkoutReminderState(enabled: false, hour: 18, minute: 0)) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = WorkoutReminderState(
      enabled: prefs.getBool(_reminderEnabledKey) ?? false,
      hour: prefs.getInt(_reminderHourKey) ?? 18,
      minute: prefs.getInt(_reminderMinuteKey) ?? 0,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);
    state = state.copyWith(enabled: enabled);

    if (enabled) {
      await _scheduleReminder();
    } else {
      await NotificationService().cancelNotification(1);
    }
  }

  Future<void> setTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, hour);
    await prefs.setInt(_reminderMinuteKey, minute);
    state = state.copyWith(hour: hour, minute: minute);

    if (state.enabled) {
      await _scheduleReminder();
    }
  }

  Future<void> _scheduleReminder() async {
    await NotificationService().scheduleDailyReminder(
      id: 1,
      title: 'Time to Workout!',
      body: 'Don\'t forget to log your workout today',
      hour: state.hour,
      minute: state.minute,
    );
  }
}
