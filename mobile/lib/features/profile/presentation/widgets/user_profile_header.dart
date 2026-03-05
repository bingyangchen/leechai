import 'package:flutter/material.dart';

class UserProfileHeader extends StatelessWidget {
  const UserProfileHeader({
    super.key,
    this.isLoggedIn = true,
    this.userName = 'Lee Chai',
    this.userEmail = 'lee@example.com',
  });

  final bool isLoggedIn;
  final String userName;
  final String userEmail;

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
          onTap: () {
            // TODO: 導航至「帳號管理頁面」或「登入頁面」
          },
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
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 20,
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
                        isLoggedIn ? userName : '尚未登入',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isLoggedIn ? userEmail : '點擊登入以啟用雲端同步',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
