import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A rest timer widget that counts down between sets.
class RestTimer extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const RestTimer({
    super.key,
    this.initialSeconds = 90,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        // Haptic feedback at 3, 2, 1
        if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
          HapticFeedback.lightImpact();
        }
      } else {
        _timer?.cancel();
        HapticFeedback.heavyImpact();
        widget.onComplete?.call();
        setState(() {
          _isRunning = false;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = widget.initialSeconds;
      _isRunning = false;
      _isPaused = false;
    });
  }

  void _addTime(int seconds) {
    setState(() {
      _remainingSeconds += seconds;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    return _remainingSeconds / widget.initialSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _getProgress();
    final isLowTime = _remainingSeconds <= 10;

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
                    _timer?.cancel();
                    widget.onCancel?.call();
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
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade300,
                    color: isLowTime ? Colors.red : theme.colorScheme.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLowTime ? Colors.red : null,
                      ),
                    ),
                    if (_remainingSeconds == 0)
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
                  onPressed: () => _addTime(15),
                  child: const Text('+15s'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _addTime(30),
                  child: const Text('+30s'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _addTime(60),
                  child: const Text('+1m'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning && !_isPaused)
                  FilledButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  )
                else if (_isRunning && !_isPaused)
                  FilledButton.icon(
                    onPressed: _pauseTimer,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  )
                else if (_isPaused)
                  FilledButton.icon(
                    onPressed: _resumeTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Skip button
            if (_isRunning || _isPaused)
              TextButton(
                onPressed: () {
                  _timer?.cancel();
                  widget.onComplete?.call();
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
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RestTimer(
          initialSeconds: initialSeconds,
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
  final int defaultSeconds;

  const RestTimerButton({
    super.key,
    this.defaultSeconds = 90,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => showRestTimerBottomSheet(
        context,
        initialSeconds: defaultSeconds,
      ),
      icon: const Icon(Icons.timer),
      label: const Text('Rest Timer'),
    );
  }
}
