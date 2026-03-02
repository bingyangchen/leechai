import 'package:flutter/material.dart';
import 'package:mobile/shared/scopes/data_refresh.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shell.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final ValueNotifier<int> _dataRefreshTrigger = ValueNotifier(0);

  @override
  void dispose() {
    _dataRefreshTrigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leechai',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) => DataRefreshScope(
        triggerRefresh: () => _dataRefreshTrigger.value++,
        child: child!,
      ),
      home: Shell(refreshTrigger: _dataRefreshTrigger),
    );
  }
}
