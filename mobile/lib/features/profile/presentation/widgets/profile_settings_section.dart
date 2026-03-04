import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({
    super.key,
    required this.totalBudgetSummary,
    required this.refreshTrigger,
  });

  final double? totalBudgetSummary;
  final ValueListenable<int>? refreshTrigger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.folder_outlined, title: '財務管理'),
          _TileGroup(
            children: [
              _SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: '預算設定',
                trailing: totalBudgetSummary != null
                    ? '\$${formatAmountForDisplay(totalBudgetSummary!)}'
                    : null,
                onTap: () => _pushPlaceholderPage(context, '預算設定'), // TODO
              ),
              _SettingsTile(
                icon: Icons.category_outlined,
                title: '分類管理',
                onTap: () => _pushPlaceholderPage(context, '分類管理'), // TODO
              ),
              _SettingsTile(
                icon: Icons.label_outline,
                title: '標籤管理',
                onTap: () => _pushPlaceholderPage(context, '標籤管理'), // TODO
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SectionHeader(icon: Icons.settings_outlined, title: '系統設定'),
          _TileGroup(
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: '外觀設定',
                onTap: () => _pushPlaceholderPage(context, '外觀設定'), // TODO
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: '提醒與通知',
                onTap: () => _pushPlaceholderPage(context, '提醒與通知'), // TODO
              ),
              _SettingsTile(
                icon: Icons.backup_outlined,
                title: '資料備份與匯出',
                onTap: () => _pushPlaceholderPage(context, '資料備份與匯出'), // TODO
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SectionHeader(icon: Icons.info_outline, title: '關於'),
          _TileGroup(
            children: [
              _SettingsTile(
                icon: Icons.rate_review_outlined,
                title: '評價與回饋',
                onTap: () => _pushPlaceholderPage(context, '評價與回饋'), // TODO
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: '版本資訊',
                onTap: () => _pushPlaceholderPage(context, '版本資訊'), // TODO
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pushPlaceholderPage(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const Center(child: Text('敬請期待')),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final list = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      list.add(children[i]);
      if (i < children.length - 1) list.add(const Divider(height: 1));
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: list),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingWidget = trailing != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trailing!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 24,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          )
        : const Icon(Icons.chevron_right);
    return ListTile(
      leading: Icon(icon, size: 24, color: theme.colorScheme.onSurface),
      title: Text(title),
      trailing: trailingWidget,
      onTap: onTap,
    );
  }
}
