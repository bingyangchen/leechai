import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/features/profile/data/repositories/notification_settings.dart';
import 'package:mobile/features/profile/data/services/daily_reminder_notification.dart';

Future<void> bootstrapProfileNotifications(
  FlutterLocalNotificationsPlugin plugin,
) async {
  DailyReminderNotificationService.instance.setPlugin(plugin);
  final repository = NotificationSettingsRepository();
  final notificationSettings = await repository.load();
  await DailyReminderNotificationService.instance.applySettings(notificationSettings);
}
