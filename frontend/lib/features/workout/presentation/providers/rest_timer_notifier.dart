import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:liftlink/features/workout/presentation/providers/rest_timer_state.dart';

/// StateNotifier for managing rest timer state.
class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;
  final VoidCallback? onComplete;
  final void Function()? onShowNotification;

  RestTimerNotifier({
    required int initialSeconds,
    this.onComplete,
    this.onShowNotification,
  }) : super(
         RestTimerState(
           initialSeconds: initialSeconds,
           remainingSeconds: initialSeconds,
         ),
       );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void start() {
    if (!state.canStart && !state.canResume) return;

    state = state.copyWith(isRunning: true, isPaused: false, isComplete: false);

    // Request permissions on first start
    if (!state.permissionsRequested) {
      state = state.copyWith(permissionsRequested: true);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (state.remainingSeconds > 0) {
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);

      // Haptic feedback at 3, 2, 1
      if (state.remainingSeconds <= 3 && state.remainingSeconds > 0) {
        HapticFeedback.lightImpact();
      }
    } else {
      _timer?.cancel();
      HapticFeedback.heavyImpact();

      state = state.copyWith(isRunning: false, isComplete: true);

      // Trigger notification
      onShowNotification?.call();

      // Trigger completion callback
      onComplete?.call();
    }
  }

  void pause() {
    if (!state.canPause) return;

    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    if (!state.canResume) return;
    start();
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: state.initialSeconds,
      isRunning: false,
      isPaused: false,
      isComplete: false,
    );
  }

  void addTime(int seconds) {
    state = state.copyWith(remainingSeconds: state.remainingSeconds + seconds);
  }

  void cancel() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, isPaused: false);
  }
}

/// Provider family for rest timer, keyed by initial seconds.
/// Using autoDispose so timer is cleaned up when widget is removed.
final restTimerProvider = StateNotifierProvider.autoDispose
    .family<RestTimerNotifier, RestTimerState, RestTimerParams>((ref, params) {
      return RestTimerNotifier(
        initialSeconds: params.initialSeconds,
        onComplete: params.onComplete,
        onShowNotification: params.onShowNotification,
      );
    });

/// Parameters for the rest timer provider.
class RestTimerParams {
  final int initialSeconds;
  final VoidCallback? onComplete;
  final VoidCallback? onShowNotification;

  const RestTimerParams({
    required this.initialSeconds,
    this.onComplete,
    this.onShowNotification,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestTimerParams &&
          runtimeType == other.runtimeType &&
          initialSeconds == other.initialSeconds;

  @override
  int get hashCode => initialSeconds.hashCode;
}
