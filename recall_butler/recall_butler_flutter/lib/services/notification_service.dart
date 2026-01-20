import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return; // Skip on web - not supported

    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // macOS settings
    const macSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('✅ Notification service initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iOS = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !_isInitialized) {
      debugPrint('📢 [Web/Not initialized] Notification: $title - $body');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'recall_butler_channel',
      'Recall Butler',
      channelDescription: 'Notifications from your Butler',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFF5B041), // Gold accent color
      enableLights: true,
      ledColor: Color(0xFFF5B041),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Schedule a notification for a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (kIsWeb || !_isInitialized) {
      debugPrint('📅 [Web/Not initialized] Scheduled: $title at $scheduledTime');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'recall_butler_reminders',
      'Reminders',
      channelDescription: 'Scheduled reminders from Butler',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFF5B041),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    if (kIsWeb || !_isInitialized) return;
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (kIsWeb || !_isInitialized) return;
    await _notifications.cancelAll();
  }

  // ========== Convenience Methods for Recall Butler ==========

  /// Notify when a new suggestion is created
  Future<void> notifyNewSuggestion({
    required int suggestionId,
    required String title,
    required String description,
  }) async {
    await showNotification(
      id: 1000 + suggestionId,
      title: '💡 Butler Suggestion',
      body: '$title\n$description',
      payload: 'suggestion:$suggestionId',
    );
  }

  /// Notify when document processing is complete
  Future<void> notifyDocumentReady({
    required int documentId,
    required String title,
  }) async {
    await showNotification(
      id: 2000 + documentId,
      title: '✅ Memory Saved',
      body: '"$title" has been processed and indexed',
      payload: 'document:$documentId',
    );
  }

  /// Schedule a reminder notification
  Future<void> scheduleReminder({
    required int reminderId,
    required String title,
    required String description,
    required DateTime reminderTime,
  }) async {
    await scheduleNotification(
      id: 3000 + reminderId,
      title: '🔔 Reminder: $title',
      body: description,
      scheduledTime: reminderTime,
      payload: 'reminder:$reminderId',
    );
  }

  /// Notify about an upcoming due date
  Future<void> notifyUpcomingDueDate({
    required int documentId,
    required String title,
    required String dueDate,
  }) async {
    await showNotification(
      id: 4000 + documentId,
      title: '📅 Due Soon',
      body: '$title is due on $dueDate',
      payload: 'document:$documentId',
    );
  }

  /// Notify when voice note is saved
  Future<void> notifyVoiceNoteSaved({
    required int documentId,
    required String title,
  }) async {
    await showNotification(
      id: 5000 + documentId,
      title: '🎤 Voice Note Saved',
      body: '"$title" has been transcribed and saved',
      payload: 'document:$documentId',
    );
  }
}
