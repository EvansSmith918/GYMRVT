import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz; // <= use latest.dart
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    tz.initializeTimeZones();

    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _inited = true;
  }

  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    String title = 'Time to train',
    String body = 'Log a set or hit today\'s workout',
  }) async {
    if (!_inited) await init();
    if (kIsWeb) return; // plugin not supported on web

    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (first.isBefore(now)) first = first.add(const Duration(days: 1));

    final androidDetails = const AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Workout reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    final iosDetails = const DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      first,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) async {
    if (!_inited) await init();
    await _plugin.cancel(id);
  }
}

