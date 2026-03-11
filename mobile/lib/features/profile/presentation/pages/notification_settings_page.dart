import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/repositories/notification_settings.dart';
import '../../data/services/daily_reminder_notification.dart';
import '../../domain/notification_settings.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with WidgetsBindingObserver {
  final NotificationSettingsRepository _repository = NotificationSettingsRepository();
  NotificationSettings _settings = NotificationSettings.defaults();
  bool _loaded = false;
  bool? _notificationPermissionGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _load() async {
    final settings = await _repository.load();
    if (mounted) {
      setState(() {
        _settings = settings;
        _loaded = true;
      });
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() => _notificationPermissionGranted = status.isGranted);
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
    _checkPermission();
  }

  Future<void> _updateSettings(NotificationSettings next) async {
    final previous = _settings;
    setState(() => _settings = next);
    final success = await _repository.save(next);
    if (!mounted) return;
    if (!success) {
      setState(() => _settings = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('設定更新失敗，請稍後再試'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    await DailyReminderNotificationService.instance.applySettings(next);
  }

  Future<void> _pickReminderTime() async {
    final theme = Theme.of(context);
    final initial =
        _settings.dailyReminderTimeOfDay ??
        NotificationSettings.defaultReminderTimeOfDay;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(primary: theme.colorScheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    await _updateSettings(_settings.copyWith(dailyReminderTimeOfDay: picked));
  }

  String _formatTime(TimeOfDay time) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('通知設定'),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (_notificationPermissionGranted == false) ...[
                  _PermissionBanner(onTap: _openAppSettings),
                  const SizedBox(height: 8),
                ],
                _SectionHeader(title: '記帳提醒'),
                _SettingsGroup(
                  children: [
                    _SwitchTile(
                      title: '每日記帳提醒',
                      subtitle: '提醒您記錄今天的收支',
                      value: _settings.dailyReminderEnabled,
                      onChanged: (value) => _updateSettings(
                        _settings.copyWith(dailyReminderEnabled: value),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: _settings.dailyReminderEnabled
                          ? _ReminderTimeTile(
                              time:
                                  _settings.dailyReminderTimeOfDay ??
                                  NotificationSettings.defaultReminderTimeOfDay,
                              formatTime: _formatTime,
                              onTap: _pickReminderTime,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _SectionHeader(title: '報表與摘要'),
                _SettingsGroup(
                  children: [
                    _SwitchTile(
                      title: '財務報表通知',
                      subtitle: '當週報或月報結算完成時發送推播',
                      value: _settings.reportNotificationEnabled,
                      onChanged: (value) => _updateSettings(
                        _settings.copyWith(reportNotificationEnabled: value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _SectionHeader(title: '系統資訊'),
                _SettingsGroup(
                  children: [
                    _SwitchTile(
                      title: '系統與新功能通知',
                      subtitle: '接收重要的系統維護與新功能發布消息',
                      value: _settings.systemNotificationEnabled,
                      onChanged: (value) => _updateSettings(
                        _settings.copyWith(systemNotificationEnabled: value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.outline,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '請至系統設定開啟通知權限，以接收提醒。',
                  style: theme.textStyles.body.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              Text(
                '前往設定',
                style: theme.textStyles.labelEmphasis.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: theme.textStyles.labelEmphasis.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textStyles;

    return ListTile(
      title: Text(title, style: textStyles.title),
      subtitle: Text(subtitle, style: textStyles.bodyMuted),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          if (newValue) HapticFeedback.lightImpact();
          onChanged(newValue);
        },
      ),
    );
  }
}

class _ReminderTimeTile extends StatelessWidget {
  const _ReminderTimeTile({
    required this.time,
    required this.formatTime,
    required this.onTap,
  });

  final TimeOfDay time;
  final String Function(TimeOfDay) formatTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        title: Text('提醒時間', style: textStyles.bodyLarge),
        trailing: Text(
          formatTime(time),
          style: textStyles.bodyLarge.copyWith(color: colorScheme.primary),
        ),
        onTap: onTap,
      ),
    );
  }
}
