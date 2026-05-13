import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Berlin'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  // Schedule a daily streak reminder at 20:00 local time
  static Future<void> scheduleStreakReminder() async {
    await init();
    const id = 1;
    await _plugin.cancel(id);

    final now    = tz.TZDateTime.now(tz.local);
    var   fireAt = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    if (fireAt.isBefore(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      '🔥 Streak nicht vergessen!',
      'Du hast heute noch keine Aufgabe gelöst. Dein Streak wartet auf dich!',
      fireAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminder', 'Streak-Erinnerung',
          channelDescription: 'Tägliche Erinnerung, die Streak am Leben zu halten',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelStreakReminder() async {
    await init();
    await _plugin.cancel(1);
  }

  // Call this when the user completes a task today
  static Future<void> onTaskCompleted() async {
    await cancelStreakReminder();
    // Re-schedule for tomorrow
    await scheduleStreakReminder();
  }
}
