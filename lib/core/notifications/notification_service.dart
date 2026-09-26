import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../native/device_channel.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static final ValueNotifier<String?> onNotificationPayload =
      ValueNotifier<String?>(null);

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final deviceTimezone = await DeviceChannel.getTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTimezone));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          onNotificationPayload.value = response.payload;
        }
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) {
        onNotificationPayload.value = payload;
      }
    }

    _initialized = true;
  }

  static Future<bool> areNotificationsGranted() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await androidPlugin?.areNotificationsEnabled() ?? false;
  }

  static Future<bool> requestNotificationPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await androidPlugin?.requestNotificationsPermission() ?? false;
  }

  static Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await androidPlugin?.requestExactAlarmsPermission() ?? false;
  }

  static Future<void> scheduleReminder({
    required int callId,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    final canExact = await canScheduleExactAlarms();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.zonedSchedule(
      callId,
      title,
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'call_reminders',
          'Call Reminders',
          channelDescription: 'Reminders for calls you flagged to follow up on',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: 'call:$callId',
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int callId) async {
    await _plugin.cancel(callId);
  }

  static Future<void> showInsight({
    required String title,
    required String body,
    String? payload,
  }) async {
    final hasPermission = await areNotificationsGranted();
    if (!hasPermission) return;

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'analytics_insights',
          'Analytics Insights',
          channelDescription: 'Occasional highlights about your calling activity',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: payload,
    );
  }

  static Future<void> showMissedCallAlert({
    required int callId,
    required String contactName,
    required String number,
  }) async {
    final hasPermission = await areNotificationsGranted();
    if (!hasPermission) return;

    await _plugin.show(
      callId.remainder(100000),
      '📞 Missed call from $contactName',
      'Tap to view call details for $number',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'missed_call_alerts',
          'Missed Call Alerts',
          channelDescription: 'Alerts for missed calls from favorite contacts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: 'call:$callId',
    );
  }

  static Future<void> showFavoriteInactivityAlert({
    required String contactName,
    required String number,
    required int daysSince,
  }) async {
    final hasPermission = await areNotificationsGranted();
    if (!hasPermission) return;

    await _plugin.show(
      number.hashCode.abs().remainder(100000),
      '💛 Stay in touch with $contactName',
      'It\'s been $daysSince days since your last call.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'favorite_reminders',
          'Favorite Reminders',
          channelDescription:
              'Gentle reminders to stay in touch with your favorite contacts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: 'contact:$number',
    );
  }

  static Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  static Future<bool> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  static Future<void> showTestNotification() async {
    await _plugin.show(
      999999,
      'Test Notification',
      'If you see this, notifications are working.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'call_reminders',
          'Call Reminders',
          channelDescription: 'Reminders for calls you flagged to follow up on',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
