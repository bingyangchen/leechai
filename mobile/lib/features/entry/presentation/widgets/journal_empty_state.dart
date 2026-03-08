import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class JournalEmptyState extends StatelessWidget {
  const JournalEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '這個月還沒有任何紀錄喔！',
              style: theme.textStyles.titleMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '點擊下方的 + 開始記下第一筆帳吧。',
              style: theme.textStyles.bodyMuted.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
