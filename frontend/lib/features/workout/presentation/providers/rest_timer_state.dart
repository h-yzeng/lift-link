import 'package:freezed_annotation/freezed_annotation.dart';

part 'rest_timer_state.freezed.dart';

/// Immutable state for the rest timer widget.
@freezed
abstract class RestTimerState with _$RestTimerState {
  const factory RestTimerState({
    required int initialSeconds,
    required int remainingSeconds,
    @Default(false) bool isRunning,
    @Default(false) bool isPaused,
    @Default(false) bool permissionsRequested,
    @Default(false) bool isComplete,
  }) = _RestTimerState;

  const RestTimerState._();

  /// Progress from 0.0 (complete) to 1.0 (full time remaining)
  double get progress =>
      initialSeconds > 0 ? remainingSeconds / initialSeconds : 0.0;

  /// Whether the timer is in low time state (last 10 seconds)
  bool get isLowTime => remainingSeconds <= 10 && remainingSeconds > 0;

  /// Formatted time string (MM:SS)
  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Whether the timer can be started
  bool get canStart => !isRunning && !isPaused && remainingSeconds > 0;

  /// Whether the timer can be paused
  bool get canPause => isRunning && !isPaused;

  /// Whether the timer can be resumed
  bool get canResume => isPaused;
}
