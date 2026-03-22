import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

Future<FlutterLocalNotificationsPlugin> initializeLocalNotificationsPlugin() async {
  timezone_data.initializeTimeZones();
  final timeZoneName = await FlutterTimezone.getLocalTimezone();
  timezone.setLocalLocation(timezone.getLocation(timeZoneName));

  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwin = DarwinInitializationSettings();
  const settings = InitializationSettings(android: android, iOS: darwin);
  await plugin.initialize(settings);
  return plugin;
}
