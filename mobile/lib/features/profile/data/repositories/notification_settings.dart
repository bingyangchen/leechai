import 'package:flutter/material.dart';
import 'package:mobile/features/profile/domain/notification_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyDailyReminderEnabled = 'notification_daily_reminder_enabled';
const _keyDailyReminderHour = 'notification_daily_reminder_hour';
const _keyDailyReminderMinute = 'notification_daily_reminder_minute';
const _keyReportEnabled = 'notification_report_enabled';
const _keySystemEnabled = 'notification_system_enabled';

class NotificationSettingsRepository {
  Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyEnabled = prefs.getBool(_keyDailyReminderEnabled) ?? false;
    final hour =
        prefs.getInt(_keyDailyReminderHour) ??
        NotificationSettings.defaultReminderTimeOfDay.hour;
    final minute =
        prefs.getInt(_keyDailyReminderMinute) ??
        NotificationSettings.defaultReminderTimeOfDay.minute;
    final reportEnabled = prefs.getBool(_keyReportEnabled) ?? true;
    final systemEnabled = prefs.getBool(_keySystemEnabled) ?? true;
    return NotificationSettings(
      dailyReminderEnabled: dailyEnabled,
      dailyReminderTimeOfDay: TimeOfDay(hour: hour, minute: minute),
      reportNotificationEnabled: reportEnabled,
      systemNotificationEnabled: systemEnabled,
    );
  }

  Future<bool> save(NotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDailyReminderEnabled, settings.dailyReminderEnabled);
      final time =
          settings.dailyReminderTimeOfDay ??
          NotificationSettings.defaultReminderTimeOfDay;
      await prefs.setInt(_keyDailyReminderHour, time.hour);
      await prefs.setInt(_keyDailyReminderMinute, time.minute);
      await prefs.setBool(_keyReportEnabled, settings.reportNotificationEnabled);
      await prefs.setBool(_keySystemEnabled, settings.systemNotificationEnabled);
      return true;
    } catch (_) {
      return false;
    }
  }
}
