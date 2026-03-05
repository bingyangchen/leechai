import 'package:flutter/material.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class UserStatsCard extends StatelessWidget {
  const UserStatsCard({super.key, required this.data});
  final ProfilePageData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroColors = HeroCardColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surface]
          : [theme.colorScheme.primary, theme.colorScheme.onPrimary],
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: heroColors.shadowSubtle,
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _HeroStreakBlock(
                    value: '${data.weeklyStreak}',
                    label: '連續活躍週',
                    contentColor: heroColors.content,
                    contentColorMuted: heroColors.contentMuted,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _AuxStatBlock(
                              icon: Icons.edit_note,
                              value: '${data.totalEntries}',
                              label: '總記帳數',
                              contentColor: heroColors.content,
                              contentColorMuted: heroColors.contentMuted,
                            ),
                          ),
                          Expanded(
                            child: _AuxStatBlock(
                              icon: Icons.calendar_today,
                              value: '${data.totalDays}',
                              label: '累積天數',
                              contentColor: heroColors.content,
                              contentColorMuted: heroColors.contentMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _BadgeProgressBlock(
                              unlocked: data.unlockedBadgesCount,
                              total: data.totalBadgesCount,
                              contentColor: heroColors.content,
                              contentColorMuted: heroColors.contentMuted,
                            ),
                          ),
                          Expanded(
                            child: _AuxStatBlock(
                              icon: Icons.bar_chart,
                              value: '${data.entriesThisMonth}',
                              label: '本月記帳',
                              contentColor: heroColors.content,
                              contentColorMuted: heroColors.contentMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 12,
            child: Text(
              'Leechai',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
                color: heroColors.contentMuted.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStreakBlock extends StatelessWidget {
  const _HeroStreakBlock({
    required this.value,
    required this.label,
    required this.contentColor,
    required this.contentColorMuted,
  });

  final String value;
  final String label;
  final Color contentColor;
  final Color contentColorMuted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.local_fire_department, size: 40, color: contentColor),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: contentColor,
                height: 1.0,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: contentColorMuted,
          ),
        ),
      ],
    );
  }
}

class _BadgeProgressBlock extends StatelessWidget {
  const _BadgeProgressBlock({
    required this.unlocked,
    required this.total,
    required this.contentColor,
    required this.contentColorMuted,
  });

  final int unlocked;
  final int total;
  final Color contentColor;
  final Color contentColorMuted;

  static const double _size = 40;
  static const double _strokeWidth = 2.5;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (unlocked / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: _strokeWidth,
                backgroundColor: contentColorMuted.withValues(alpha: 0.35),
                valueColor: AlwaysStoppedAnimation<Color>(contentColor),
              ),
              Icon(Icons.emoji_events, size: _iconSize, color: contentColorMuted),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '收集徽章',
          style: TextStyle(fontSize: 11, color: contentColorMuted),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

class _AuxStatBlock extends StatelessWidget {
  const _AuxStatBlock({
    required this.icon,
    required this.value,
    required this.label,
    required this.contentColor,
    required this.contentColorMuted,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color contentColor;
  final Color contentColorMuted;

  static const double _iconSize = 20;
  static const double _valueFontSize = 20;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: _iconSize, color: contentColorMuted),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: _valueFontSize,
            fontWeight: FontWeight.w600,
            color: contentColor,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: contentColorMuted),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}
