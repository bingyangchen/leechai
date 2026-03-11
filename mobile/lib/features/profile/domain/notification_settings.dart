import 'package:flutter/material.dart';

class NotificationSettings {
  static const TimeOfDay defaultReminderTimeOfDay = TimeOfDay(hour: 20, minute: 0);

  const NotificationSettings({
    required this.dailyReminderEnabled,
    required this.dailyReminderTimeOfDay,
    required this.reportNotificationEnabled,
    required this.systemNotificationEnabled,
  });

  factory NotificationSettings.defaults() {
    return const NotificationSettings(
      dailyReminderEnabled: false,
      dailyReminderTimeOfDay: null,
      reportNotificationEnabled: true,
      systemNotificationEnabled: true,
    );
  }

  final bool dailyReminderEnabled;
  final TimeOfDay? dailyReminderTimeOfDay;
  final bool reportNotificationEnabled;
  final bool systemNotificationEnabled;

  NotificationSettings copyWith({
    bool? dailyReminderEnabled,
    TimeOfDay? dailyReminderTimeOfDay,
    bool? reportNotificationEnabled,
    bool? systemNotificationEnabled,
  }) {
    return NotificationSettings(
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTimeOfDay: dailyReminderTimeOfDay ?? this.dailyReminderTimeOfDay,
      reportNotificationEnabled:
          reportNotificationEnabled ?? this.reportNotificationEnabled,
      systemNotificationEnabled:
          systemNotificationEnabled ?? this.systemNotificationEnabled,
    );
  }
}
