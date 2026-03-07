import 'package:flutter/material.dart';
import 'package:mobile/features/entry/presentation/pages/entry_page.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
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
    const ringStrokeWidth = 4.0;
    final colorScheme = Theme.of(context).colorScheme;
    final appTextStyles = AppTextStyles.of(context);
    final primary = colorScheme.primary;
    final primaryContainer = colorScheme.primaryContainer;

    Widget badgeIcon = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!item.isUnlocked && item.target > 0)
            SizedBox(
              width: size,
              height: size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: item.progress),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: ringStrokeWidth,
                    strokeCap: StrokeCap.round,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      primary.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: size - ringStrokeWidth - 4,
              height: size - ringStrokeWidth - 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: item.isUnlocked
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary.withValues(alpha: 0.35),
                          primaryContainer,
                          primary.withValues(alpha: 0.2),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : null,
                color: item.isUnlocked ? null : primaryContainer.withValues(alpha: 0.6),
                boxShadow: item.isUnlocked
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: primary.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _iconForId(item.id),
                size: 32,
                color: item.isUnlocked
                    ? primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
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
            style: item.isUnlocked
                ? appTextStyles.labelEmphasis
                : appTextStyles.labelMuted,
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
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                '${item.current}/${item.target}',
                style: appTextStyles.labelSmallMuted,
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
              style: appTextStyles.labelEmphasis.copyWith(color: colorScheme.primary),
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
          border: Border.all(color: colorScheme.primary, width: 1.5),
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
