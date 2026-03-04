import 'package:flutter/material.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';

class UserStatsCard extends StatelessWidget {
  const UserStatsCard({super.key, required this.data});
  final ProfilePageData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: _StatBlock(
                icon: Icons.local_fire_department,
                value: '${data.weeklyStreak}',
                label: '連續活躍週',
                theme: theme,
              ),
            ),
            Expanded(
              child: _StatBlock(
                icon: Icons.edit_note,
                value: '${data.totalEntries}',
                label: '總記帳數',
                theme: theme,
              ),
            ),
            Expanded(
              child: _StatBlock(
                icon: Icons.block,
                value: '${data.noSpendDaysThisWeek}',
                label: '無消費日',
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.value,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final String value;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
