import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Service for managing local notifications
///
/// Handles initialization, permission requests, and showing notifications
/// for features like rest timer completion.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize the notification service
  ///
  /// This should be called during app startup.
  /// Returns true if initialization was successful.
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Android initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // We'll request explicitly
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = initialized ?? false;
      return _initialized;
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      return false;
    }
  }

  /// Request notification permissions (iOS only, Android grants automatically)
  ///
  /// Returns true if permissions were granted.
  Future<bool> requestPermissions() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Android doesn't need runtime permission request for notifications
      if (defaultTargetPlatform == TargetPlatform.android) {
        return true;
      }

      // Request iOS permissions
      final granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      return granted ?? false;
    } catch (e) {
      debugPrint('Failed to request notification permissions: $e');
      return false;
    }
  }

  /// Show a notification for rest timer completion
  ///
  /// Parameters:
  /// - [exerciseName]: Name of the exercise that just completed rest
  /// - [restSeconds]: Number of seconds that were rested
  Future<void> showRestTimerNotification({
    required String exerciseName,
    required int restSeconds,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      const notificationId = 1; // Use same ID to replace previous notifications

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'rest_timer_channel',
        'Rest Timer',
        channelDescription: 'Notifications for rest timer completion',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      const title = 'Rest Complete!';
      final body = 'Time to get back to $exerciseName';

      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Failed to show rest timer notification: $e');
    }
  }

  /// Cancel all pending notifications
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel notifications: $e');
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancel(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Failed to cancel notification $id: $e');
    }
  }

  /// Handle notification tap
  ///
  /// When user taps a notification, this callback is invoked.
  /// Currently, it just brings the app to foreground.
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // The app will automatically come to foreground
    // Additional navigation logic can be added here if needed
  }
}
