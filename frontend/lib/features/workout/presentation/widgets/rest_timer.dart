import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/providers/core_providers.dart';
import 'package:liftlink/features/workout/presentation/providers/rest_timer_notifier.dart';
import 'package:liftlink/features/workout/presentation/providers/rest_timer_state.dart';

/// A rest timer widget that counts down between sets.
class RestTimer extends ConsumerWidget {
  final int initialSeconds;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final String? exerciseName;

  const RestTimer({
    super.key,
    this.initialSeconds = 90,
    this.onComplete,
    this.onCancel,
    this.exerciseName,
  });

  void _showCompletionNotification(WidgetRef ref) {
    final notificationService = ref.read(notificationServiceProvider);
    final name = exerciseName ?? 'your exercise';

    notificationService.showRestTimerNotification(
      exerciseName: name,
      restSeconds: initialSeconds,
    );
  }

  void _requestPermissions(WidgetRef ref) {
    final notificationService = ref.read(notificationServiceProvider);
    notificationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Create params for the provider
    final params = RestTimerParams(
      initialSeconds: initialSeconds,
      onComplete: () {
        _showCompletionNotification(ref);
        onComplete?.call();
      },
      onShowNotification: () => _showCompletionNotification(ref),
    );

    final RestTimerState state = ref.watch(restTimerProvider(params));
    final RestTimerNotifier notifier =
        ref.read(restTimerProvider(params).notifier);

    // Request permissions on first start
    if (state.isRunning && !state.permissionsRequested) {
      _requestPermissions(ref);
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rest Timer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    notifier.cancel();
                    onCancel?.call();
                  },
                  tooltip: 'Cancel',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Circular progress indicator with time
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: state.progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade300,
                    color: state.isLowTime
                        ? Colors.red
                        : theme.colorScheme.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.formattedTime,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: state.isLowTime ? Colors.red : null,
                      ),
                    ),
                    if (state.isComplete)
                      Text(
                        'Rest Complete!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick add time buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => notifier.addTime(15),
                  child: const Text('+15s'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => notifier.addTime(30),
                  child: const Text('+30s'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => notifier.addTime(60),
                  child: const Text('+1m'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.canStart)
                  FilledButton.icon(
                    onPressed: notifier.start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  )
                else if (state.canPause)
                  FilledButton.icon(
                    onPressed: notifier.pause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  )
                else if (state.canResume)
                  FilledButton.icon(
                    onPressed: notifier.resume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: notifier.reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Skip button
            if (state.isRunning || state.isPaused)
              TextButton(
                onPressed: () {
                  notifier.cancel();
                  onComplete?.call();
                },
                child: const Text('Skip Rest'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows the rest timer in a bottom sheet.
Future<void> showRestTimerBottomSheet(
  BuildContext context, {
  int initialSeconds = 90,
  String? exerciseName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RestTimer(
          initialSeconds: initialSeconds,
          exerciseName: exerciseName,
          onComplete: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rest complete! Time for your next set.'),
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );
}

/// A compact rest timer button that can be added to the workout page.
class RestTimerButton extends StatelessWidget {
  final int? defaultSeconds;

  const RestTimerButton({
    super.key,
    this.defaultSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => showRestTimerBottomSheet(
        context,
        initialSeconds: defaultSeconds ?? 90,
      ),
      icon: const Icon(Icons.timer),
      label: const Text('Rest Timer'),
    );
  }
}
