import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

const _appVersion = 'v1.0.0';
const _privacyPolicyUrl = 'https://github.com/bingyangchen/leechai';
const _termsOfServiceUrl = 'https://github.com/bingyangchen/leechai';

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
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: '財務管理'),
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
          _SectionHeader(title: '系統設定'),
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
          _SectionHeader(title: '關於'),
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
                trailing: _appVersion,
                onTap: () => _showAboutBottomSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('無法開啟連結')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('無法開啟連結')));
      }
    }
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

  void _showAboutBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    showAppBottomSheet<void>(
      context,
      mode: AppBottomSheetMode.static,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            // TODO: replace with app icon
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 40,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text('LeeChai', style: theme.textStyles.headlineSmallEmphasis),
          const SizedBox(height: 4),
          Text(_appVersion, style: theme.textStyles.bodyMuted),
          const SizedBox(height: 24),
          _AboutSheetTile(
            icon: Icons.description_outlined,
            title: '隱私權政策',
            trailing: Icons.open_in_new,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _openInBrowser(context, _privacyPolicyUrl);
            },
          ),
          _AboutSheetTile(
            icon: Icons.gavel_outlined,
            title: '服務條款',
            trailing: Icons.open_in_new,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _openInBrowser(context, _termsOfServiceUrl);
            },
          ),
          _AboutSheetTile(
            icon: Icons.code_outlined,
            title: '開源授權',
            trailing: Icons.chevron_right,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _pushPlaceholderPage(context, '開源授權');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AboutSheetTile extends StatelessWidget {
  const _AboutSheetTile({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title),
      trailing: Icon(
        trailing,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      onTap: onTap,
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

class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.children});
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

  static const double _iconBoxSize = 32;
  static const double _iconBoxRadius = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingWidget = trailing != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trailing!,
                style: theme.textStyles.bodyMuted.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 24,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          )
        : Icon(
            Icons.chevron_right,
            size: 24,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          );
    return ListTile(
      leading: Container(
        width: _iconBoxSize,
        height: _iconBoxSize,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(_iconBoxRadius),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      ),
      title: Text(title),
      trailing: trailingWidget,
      onTap: onTap,
    );
  }
}
