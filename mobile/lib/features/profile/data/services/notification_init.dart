import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:mobile/features/profile/data/repositories/notification_settings.dart';
import 'package:mobile/features/profile/data/services/daily_reminder_notification.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

Future<void> initNotificationService() async {
  timezone_data.initializeTimeZones();
  final timeZoneName = await FlutterTimezone.getLocalTimezone();
  timezone.setLocalLocation(timezone.getLocation(timeZoneName));

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwin = DarwinInitializationSettings();
  const settings = InitializationSettings(android: android, iOS: darwin);
  await _plugin.initialize(settings);

  DailyReminderNotificationService.instance.setPlugin(_plugin);

  final repository = NotificationSettingsRepository();
  final notificationSettings = await repository.load();
  await DailyReminderNotificationService.instance.applySettings(notificationSettings);
}
