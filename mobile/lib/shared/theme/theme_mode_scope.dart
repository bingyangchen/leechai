import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModeKey = 'theme_mode';

Future<ThemeMode> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(_themeModeKey);
  if (stored == null) return ThemeMode.system;
  switch (stored) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

Future<void> saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themeModeKey, mode.name);
}

class ThemeModeScope extends InheritedWidget {
  const ThemeModeScope({
    super.key,
    required this.themeMode,
    required this.setThemeMode,
    required super.child,
  });

  final ThemeMode themeMode;
  final void Function(ThemeMode) setThemeMode;

  static ThemeModeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeModeScope>();
    assert(scope != null, 'ThemeModeScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(ThemeModeScope oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}
