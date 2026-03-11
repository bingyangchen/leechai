import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as timezone;

import '../../domain/notification_settings.dart';

const int _dailyReminderNotificationId = 1;
const String _channelId = 'daily_reminder';
const String _channelName = '每日記帳提醒';
const String _notificationBody = '提醒您記錄今天的收支';

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
      _channelName,
      channelDescription: _notificationBody,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

    await plugin.zonedSchedule(
      _dailyReminderNotificationId,
      _channelName,
      _notificationBody,
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
