import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final dynamic _plugin = FlutterLocalNotificationsPlugin();
  var _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> showAlarmNotification(String title, String body) async {
    try {
      if (!_initialized) await init();

      const androidDetails = AndroidNotificationDetails(
        'safe_call_alerts',
        'Safe-Call Alerts',
        channelDescription: 'Notifications for possible phishing alerts',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails();

      const platform = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(0, title, body, platform);
    } catch (e) {
      if (kDebugMode) {
        print('Notification error: $e');
      }
    }
  }
}
