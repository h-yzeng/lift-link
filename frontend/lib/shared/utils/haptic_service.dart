import 'package:flutter/services.dart';

/// Service for providing haptic feedback throughout the app.
///
/// Usage:
/// ```dart
/// HapticService.lightTap();      // Light button taps
/// HapticService.mediumTap();     // Important actions
/// HapticService.success();       // Successful completions
/// HapticService.warning();       // Warnings or confirmations
/// HapticService.error();         // Errors
/// HapticService.selection();     // Selection changes
/// ```
class HapticService {
  HapticService._();

  /// Light tap feedback for button presses
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium tap feedback for important actions
  static Future<void> mediumTap() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap feedback for significant actions
  static Future<void> heavyTap() async {
    await HapticFeedback.heavyImpact();
  }

  /// Success feedback for completed actions (workout complete, set added)
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  /// Warning feedback for destructive or important confirmations
  static Future<void> warning() async {
    await HapticFeedback.heavyImpact();
  }

  /// Error feedback for failed actions
  static Future<void> error() async {
    await HapticFeedback.vibrate();
  }

  /// Selection change feedback (toggle, radio, dropdown)
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Timer tick feedback
  static Future<void> tick() async {
    await HapticFeedback.selectionClick();
  }

  /// Timer complete feedback
  static Future<void> timerComplete() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
