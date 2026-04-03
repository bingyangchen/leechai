import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/features/profile/data/constants/daily_reminder.dart';
import 'package:mobile/features/profile/domain/notification_settings.dart';
import 'package:timezone/timezone.dart' as timezone;

const int _dailyReminderNotificationId = 1;
const String _channelId = 'daily_reminder';

class DailyReminderNotificationService {
  DailyReminderNotificationService._();

  static final DailyReminderNotificationService instance =
      DailyReminderNotificationService._();

  FlutterLocalNotificationsPlugin? _plugin;

  void setPlugin(FlutterLocalNotificationsPlugin plugin) {
    _plugin = plugin;
  }

  Future<void> applySettings(NotificationSettings settings) async {
    if (!settings.dailyReminderEnabled) {
      await cancelDailyReminder();
      return;
    }
    final time =
        settings.dailyReminderTimeOfDay ??
        NotificationSettings.defaultReminderTimeOfDay;
    await scheduleDailyReminder(time);
  }

  Future<void> scheduleDailyReminder(TimeOfDay timeOfDay) async {
    final plugin = _plugin;
    if (plugin == null) return;

    final now = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      dailyReminderTitle,
      channelDescription: dailyReminderSubtitle,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    await plugin.zonedSchedule(
      _dailyReminderNotificationId,
      dailyReminderTitle,
      dailyReminderSubtitle,
      scheduled,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin?.cancel(_dailyReminderNotificationId);
  }
}
