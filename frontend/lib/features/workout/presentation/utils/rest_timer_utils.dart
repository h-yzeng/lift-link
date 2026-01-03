import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/preferences/rest_timer_preference.dart';
import 'package:liftlink/core/preferences/auto_start_rest_timer_preference.dart';
import 'package:liftlink/features/workout/presentation/widgets/rest_timer.dart';

/// Auto-starts rest timer if enabled in preferences
void maybeAutoStartRestTimer({
  required BuildContext context,
  required WidgetRef ref,
}) {
  final isAutoStartEnabled = ref.read(autoStartRestTimerProvider);

  if (isAutoStartEnabled) {
    final defaultSeconds = ref.read(defaultRestTimerSecondsProvider);
    // Post-frame callback to avoid showing modal during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showRestTimerBottomSheet(context, initialSeconds: defaultSeconds);
      }
    });
  }
}
