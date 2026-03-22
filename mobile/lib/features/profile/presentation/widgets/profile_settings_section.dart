import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mobile/features/budget/presentation/pages/budget_page.dart';
import 'package:mobile/features/category/presentation/pages/category_management_page.dart';
import 'package:mobile/features/profile/presentation/pages/notification_settings_page.dart';
import 'package:mobile/features/tag/presentation/pages/tag_management_page.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/theme/theme_mode_scope.dart';
import 'package:mobile/shared/utils/snackbar.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

String _themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return '跟隨系統';
    case ThemeMode.light:
      return '淺色';
    case ThemeMode.dark:
      return '深色';
  }
}

const _appVersion = 'v1.0.0';
const _privacyPolicyUrl = 'https://bingyangchen.github.io/leechai/privacy-policy/';
const _termsOfServiceUrl = 'https://bingyangchen.github.io/leechai/terms-of-service/';
const _openSourceLicensesUrl =
    'https://bingyangchen.github.io/leechai/open-source-licenses/';
const _feedbackEmail = 'leechai.app@gmail.com';

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
          _SectionHeader(title: '記帳設定'),
          _TileGroup(
            children: [
              _SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: '預算',
                trailing: totalBudgetSummary != null && totalBudgetSummary! > 0
                    ? '\$${formatAmountForDisplay(totalBudgetSummary!)}'
                    : '未設定',
                onTap: () async {
                  final saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => BudgetPage(refreshTrigger: refreshTrigger),
                    ),
                  );
                  if (saved == true && context.mounted) {
                    (refreshTrigger as ValueNotifier<int>?)?.value++;
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.category_outlined,
                title: '分類管理',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CategoryManagementPage(refreshTrigger: refreshTrigger),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.label_outline,
                title: '標籤管理',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TagManagementPage(refreshTrigger: refreshTrigger),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: '系統設定'),
          _TileGroup(
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: '主題',
                trailing: _themeModeLabel(ThemeModeScope.of(context).themeMode),
                showTrailingArrow: false,
                onTap: () => _showThemeModeBottomSheet(context),
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: '通知',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationSettingsPage(),
                  ),
                ),
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
                showTrailingArrow: false,
                onTap: () => _onFeedbackTap(context),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: '版本資訊',
                trailing: _appVersion,
                showTrailingArrow: false,
                onTap: () => _showAboutBottomSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onFeedbackTap(BuildContext context) async {
    final result = await Connectivity().checkConnectivity();
    final hasNetwork = result.any(
      (e) => e == ConnectivityResult.mobile || e == ConnectivityResult.wifi,
    );
    if (!hasNetwork) {
      if (!context.mounted) return;
      showReplacingSnackBar(context, SnackBar(content: Text('請檢查網路連線後再試')));
      return;
    }
    if (!context.mounted) return;
    _showFeedbackBottomSheet(context);
  }

  void _showFeedbackBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;
    showAppBottomSheet<void>(
      context,
      mode: AppBottomSheetMode.static,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Icon(Icons.volunteer_activism, size: 48, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                '您的回饋是我們前進的動力',
                textAlign: TextAlign.center,
                style: textStyles.titleLargeEmphasis,
              ),
              const SizedBox(height: 8),
              Text(
                '如果您喜歡這個應用程式，請給我們五星好評；如果有任何問題或建議，歡迎前往 GitHub 回報給我們！',
                textAlign: TextAlign.center,
                style: textStyles.bodyMuted,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _requestInAppReview(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.star, size: 20),
                  label: Text(
                    '五星好評',
                    style: textStyles.labelLargeEmphasis.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _openFeedbackEmail(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.bug_report_outlined, size: 20),
                  label: Text(
                    '問題回報',
                    style: textStyles.labelLargeEmphasis.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestInAppReview(BuildContext context) async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      if (!context.mounted) return;
      final theme = Theme.of(context);
      showReplacingSnackBar(
        context,
        SnackBar(
          persist: false,
          content: Text(
            '感謝您的支持！若未出現評分視窗，請點下方按鈕前往商店評分。',
            style: theme.textStyles.body.copyWith(color: theme.colorScheme.onSurface),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          action: SnackBarAction(
            label: '前往商店',
            textColor: theme.colorScheme.primary,
            onPressed: () => inAppReview.openStoreListing(),
          ),
        ),
      );
    } else {
      if (!context.mounted) return;
      await inAppReview.openStoreListing();
    }
  }

  Future<String> _buildFeedbackEmailBody() async {
    final deviceInfo = DeviceInfoPlugin();
    String osVersion = '';
    String deviceModel = '';
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      osVersion = 'Android ${android.version.release}';
      deviceModel = android.model;
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      osVersion = 'iOS ${ios.systemVersion}';
      deviceModel = ios.utsname.machine;
    }
    final packageInfo = await PackageInfo.fromPlatform();
    return '''
（請在此描述您遇到的問題）

---
設備資訊（請勿刪除）：
App 版本：${packageInfo.version} (${packageInfo.buildNumber})
設備型號：$deviceModel
作業系統：$osVersion
''';
  }

  Future<void> _openFeedbackEmail(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final subject = '[問題回報] ${packageInfo.appName} v${packageInfo.version}';
      final body = await _buildFeedbackEmailBody();
      final uri = Uri(
        scheme: 'mailto',
        path: _feedbackEmail,
        query:
            'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        showReplacingSnackBar(context, SnackBar(content: Text('目前無法開啟郵件，請稍後再試')));
      }
    } catch (_) {
      if (context.mounted) {
        showReplacingSnackBar(context, SnackBar(content: Text('目前無法開啟郵件，請稍後再試')));
      }
    }
  }

  Future<void> _openInBrowser(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        final theme = Theme.of(context);
        showReplacingSnackBar(
          context,
          SnackBar(
            content: Text(
              '目前無法開啟連結，請稍後再試',
              style: theme.textStyles.body.copyWith(color: theme.colorScheme.onError),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        final theme = Theme.of(context);
        showReplacingSnackBar(
          context,
          SnackBar(
            content: Text(
              '目前無法開啟連結，請稍後再試',
              style: theme.textStyles.body.copyWith(color: theme.colorScheme.onError),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  void _showThemeModeBottomSheet(BuildContext context) {
    final scope = ThemeModeScope.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    showAppBottomSheet<void>(
      context,
      mode: AppBottomSheetMode.static,
      builder: (sheetContext) {
        final current = ThemeModeScope.of(sheetContext).themeMode;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(
                  Icons.brightness_auto_outlined,
                  color: current == ThemeMode.system ? primary : onSurface,
                ),
                title: Text(
                  '跟隨系統',
                  style: theme.textStyles.body.copyWith(
                    color: current == ThemeMode.system ? primary : onSurface,
                    fontWeight: current == ThemeMode.system
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: current == ThemeMode.system
                    ? Icon(Icons.check, color: primary)
                    : null,
                onTap: () {
                  scope.setThemeMode(ThemeMode.system);
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(
                  Icons.light_mode_outlined,
                  color: current == ThemeMode.light ? primary : onSurface,
                ),
                title: Text(
                  '淺色',
                  style: theme.textStyles.body.copyWith(
                    color: current == ThemeMode.light ? primary : onSurface,
                    fontWeight: current == ThemeMode.light
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: current == ThemeMode.light
                    ? Icon(Icons.check, color: primary)
                    : null,
                onTap: () {
                  scope.setThemeMode(ThemeMode.light);
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(
                  Icons.dark_mode_outlined,
                  color: current == ThemeMode.dark ? primary : onSurface,
                ),
                title: Text(
                  '深色',
                  style: theme.textStyles.body.copyWith(
                    color: current == ThemeMode.dark ? primary : onSurface,
                    fontWeight: current == ThemeMode.dark
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: current == ThemeMode.dark
                    ? Icon(Icons.check, color: primary)
                    : null,
                onTap: () {
                  scope.setThemeMode(ThemeMode.dark);
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
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
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
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
            trailing: Icons.open_in_new,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _openInBrowser(context, _openSourceLicensesUrl);
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
    this.showTrailingArrow = true,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final bool showTrailingArrow;
  final VoidCallback onTap;

  static const double _iconBoxSize = 32;
  static const double _iconBoxRadius = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showArrow = showTrailingArrow;
    Widget trailingWidget;
    if (trailing != null && trailing!.isNotEmpty) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailing!,
            style: theme.textStyles.bodyMuted.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          if (showArrow) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 24,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ],
      );
    } else {
      trailingWidget = showArrow
          ? Icon(
              Icons.chevron_right,
              size: 24,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            )
          : const SizedBox.shrink();
    }
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
