import 'package:flutter/material.dart';
import 'package:mobile/features/entry/presentation/pages/entry_page.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/shared/utils/date_time_utils.dart';

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
  static const _grayscaleFilter = ColorFilter.matrix([
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    final theme = Theme.of(context);

    Widget badgeIcon = Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(size / 2),
      elevation: item.isUnlocked ? 2 : 0,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            _iconForId(item.id),
            size: 36,
            color: item.isUnlocked
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
    if (!item.isUnlocked) {
      badgeIcon = ColorFiltered(colorFilter: _grayscaleFilter, child: badgeIcon);
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badgeIcon,
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            item.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: item.isUnlocked ? FontWeight.w600 : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!item.isUnlocked && item.target > 0) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.current}/${item.target}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
        if (item.isUnlocked && item.unlockedAt != null) ...[
          const SizedBox(height: 2),
          Text(
            formatDate(item.unlockedAt!),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
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
              '立即記下第一筆帳！',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
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

  static IconData _iconForId(String id) {
    switch (id) {
      case 'first_entry':
        return Icons.celebration;
      case 'hundred_entries':
        return Icons.stacked_bar_chart;
      case 'three_weeks_streak':
        return Icons.calendar_today;
      default:
        return Icons.emoji_events;
    }
  }
}
