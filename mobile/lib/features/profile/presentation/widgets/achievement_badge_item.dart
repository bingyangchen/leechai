import 'package:flutter/material.dart';
import 'package:mobile/features/entry/presentation/pages/entry_page.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_badge_graphics.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class AchievementBadgeItem extends StatelessWidget {
  const AchievementBadgeItem({
    super.key,
    required this.item,
    this.highlightCta = false,
    required this.onTap,
    this.onEntryAdded,
  });

  final AchievementItem item;
  final bool highlightCta;
  final VoidCallback onTap;
  final VoidCallback? onEntryAdded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final badgeIcon = GestureDetector(
      onTap: onTap,
      child: AchievementBadgeGraphics(
        size: 72,
        item: item,
        showProgressRing: true,
        glow: false,
      ),
    );

    final content = Column(
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
        if (highlightCta) ...[
          const SizedBox(height: 6),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () async {
              final added = await Navigator.of(
                context,
              ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const EntryPage()));
              if (!context.mounted) return;
              if (added == true) onEntryAdded?.call();
            },
            child: Text(
              '立即開始記帳！',
              style: theme.textStyles.labelEmphasis.copyWith(
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    if (highlightCta) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      );
    }
    return content;
  }
}
