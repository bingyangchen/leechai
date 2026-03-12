import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class UserProfileHeader extends StatelessWidget {
  const UserProfileHeader({
    super.key,
    this.isLoggedIn = false,
    this.userName = '',
    this.userEmail = '',
    this.onTap,
  });

  final bool isLoggedIn;
  final String userName;
  final String userEmail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = 16.0;

    return Container(
      margin: const EdgeInsets.all(8),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: isLoggedIn && userName.isNotEmpty
                      ? Text(
                          userName[0],
                          style: theme.textStyles.headlineSmallEmphasis.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(Icons.person_outline, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? userName : '登入 / 註冊',
                        style: theme.textStyles.titleEmphasis,
                      ),
                      Text(
                        isLoggedIn ? userEmail : '登入以啟用雲端備份，保全資料不遺失',
                        style: theme.textStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
