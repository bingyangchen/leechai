import 'package:flutter/material.dart';
import 'package:mobile/features/auth/data/services/auth.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/presentation/widgets/user_avatar.dart';
import 'package:mobile/features/profile/data/services/cloud_sync.dart';
import 'package:mobile/features/profile/presentation/pages/cloud_sync_settings_page.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class CloudSyncBanner extends StatelessWidget {
  const CloudSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser.value;
    if (user != null) {
      return _AuthenticatedBanner(user: user);
    }
    return const _UnauthenticatedBanner();
  }
}

class _UnauthenticatedBanner extends StatelessWidget {
  const _UnauthenticatedBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _pushCloudSyncSettings(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.cloud_upload_outlined, color: colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '開啟雲端備份與同步',
                        style: textStyles.titleEmphasis.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '保護資料安全，跨裝置無縫記帳',
                        style: textStyles.bodySmallMuted.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthenticatedBanner extends StatelessWidget {
  const _AuthenticatedBanner({required this.user});

  final AuthState user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;
    final syncStatus = CloudSyncService.instance.status.value;

    String statusText;
    switch (syncStatus) {
      case CloudSyncStatus.synced:
        statusText = '已同步至雲端';
      case CloudSyncStatus.syncing:
        statusText = '同步中...';
      case CloudSyncStatus.offline:
        statusText = '離線 / 未同步';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _pushCloudSyncSettings(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  UserAvatar(user: user, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.displayName,
                          style: textStyles.titleEmphasis.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusText,
                          style: textStyles.bodySmallMuted.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _pushCloudSyncSettings(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const CloudSyncSettingsPage()));
}
