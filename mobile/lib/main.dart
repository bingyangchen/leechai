import 'package:flutter/material.dart';
import 'package:mobile/features/profile/data/services/notification_init.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_notification_overlay.dart';
import 'package:mobile/shared/scopes/data_refresh.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/theme/theme_mode_scope.dart';
import 'package:mobile/shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotificationService();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final ValueNotifier<int> _dataRefreshTrigger = ValueNotifier(0);
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  ThemeMode _themeMode = ThemeMode.system;
  bool _themeLoaded = false;
  bool _overlayAttachScheduled = false;

  @override
  void initState() {
    super.initState();
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
    AchievementNotificationOverlay.instance.detach();
    _dataRefreshTrigger.dispose();
    super.dispose();
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
