import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/notifications/initialize.dart';
import 'package:mobile/features/auth/data/services/auth.dart';
import 'package:mobile/features/profile/data/services/cloud_sync.dart';
import 'package:mobile/features/profile/data/services/notification_init.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_notification_overlay.dart';
import 'package:mobile/shared/scopes/data_refresh.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/theme/theme_mode_scope.dart';
import 'package:mobile/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    // NOTE: This is only for development purposes.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  await AuthService.instance.ensureLoaded();
  await CloudSyncService.instance.ensureLoaded();
  final notificationPlugin = await initializeLocalNotificationsPlugin();
  await bootstrapProfileNotifications(notificationPlugin);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  final ValueNotifier<int> _dataRefreshTrigger = ValueNotifier(0);
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  ThemeMode _themeMode = ThemeMode.system;
  bool _themeLoaded = false;
  bool _overlayAttachScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CloudSyncService.instance.onSyncComplete = () => _dataRefreshTrigger.value++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CloudSyncService.instance.syncIfNeeded().catchError((_, stackTrace) {});
      CloudSyncService.instance.startPeriodicSync();
    });
    loadThemeMode().then((mode) {
      if (mounted) {
        setState(() {
          _themeMode = mode;
          _themeLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CloudSyncService.instance.stopPeriodicSync();
    CloudSyncService.instance.onSyncComplete = null;
    AchievementNotificationOverlay.instance.detach();
    _dataRefreshTrigger.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      CloudSyncService.instance.syncIfNeeded().catchError((_, stackTrace) {});
      CloudSyncService.instance.startPeriodicSync();
    } else if (state == AppLifecycleState.paused) {
      CloudSyncService.instance.stopPeriodicSync();
    }
  }

  void _attachAchievementOverlay() {
    if (!mounted) return;
    final overlay = _navigatorKey.currentState?.overlay;
    if (overlay != null) {
      AchievementNotificationOverlay.instance.attach(overlay);
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await saveThemeMode(mode);
    if (mounted) setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    if (!_themeLoaded) {
      return MaterialApp(
        title: 'Leechai',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return ThemeModeScope(
      themeMode: _themeMode,
      setThemeMode: _setThemeMode,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Leechai',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        builder: (context, child) {
          if (!_overlayAttachScheduled) {
            _overlayAttachScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _attachAchievementOverlay(),
            );
          }
          return DataRefreshScope(
            triggerRefresh: () => _dataRefreshTrigger.value++,
            child: child!,
          );
        },
        home: Shell(refreshTrigger: _dataRefreshTrigger),
      ),
    );
  }
}
