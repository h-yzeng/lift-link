import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/core/services/notification_service.dart';
import 'package:liftlink/core/services/streak_service.dart';

part 'core_providers.g.dart';

/// Provider for the notification service singleton
///
/// This service handles all local notifications in the app,
/// including rest timer completion notifications.
@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  final service = NotificationService();

  // Initialize the service on first access
  service.initialize();

  return service;
}

/// Provider for the streak service
///
/// This service calculates workout streaks and provides
/// motivational messages based on streak progress.
@riverpod
StreakService streakService(StreakServiceRef ref) {
  return StreakService();
}
