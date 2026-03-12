import 'package:flutter/material.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_badge_graphics.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class AchievementBadgeItem extends StatelessWidget {
  const AchievementBadgeItem({super.key, required this.item, required this.onTap});
  final AchievementItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final badgeIcon = GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AchievementBadgeGraphics(
            size: 72,
            item: item,
            showProgressRing: true,
            glow: false,
          ),
          if (item.completedCount > 1)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '×${item.completedCount}',
                  style: theme.textStyles.labelSmallMuted.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badgeIcon,
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            item.name,
            style: item.isUnlocked
                ? theme.textStyles.labelEmphasis
                : theme.textStyles.labelMuted,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!item.isUnlocked && item.target > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                '${item.current}/${item.target}',
                style: theme.textStyles.labelSmallMuted,
              ),
            ),
          ),
      ],
    );
  }
}
