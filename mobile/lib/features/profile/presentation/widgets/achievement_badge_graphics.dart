import 'package:flutter/material.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';

class AchievementBadgeGraphics extends StatelessWidget {
  const AchievementBadgeGraphics({
    super.key,
    required this.size,
    required this.item,
    this.showProgressRing = false,
    this.glow = false,
  });

  final double size;
  final AchievementItem item;
  final bool showProgressRing;
  final bool glow;

  // dart format off
  static const _grayscaleFilter = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);
  // dart format on

  static IconData iconForId(String id) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final primaryContainer = theme.colorScheme.primaryContainer;
    const ringStrokeWidth = 4.0;
    final innerSize = size - ringStrokeWidth - 4;

    final boxShadows = item.isUnlocked
        ? glow
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: primary.withValues(alpha: 0.2),
                    blurRadius: 48,
                    spreadRadius: 0,
                  ),
                ]
              : [
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
        : null;

    Widget iconContent = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showProgressRing && !item.isUnlocked && item.target > 0)
            SizedBox(
              width: size,
              height: size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: item.progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: ringStrokeWidth,
                    strokeCap: StrokeCap.round,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      primary.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
          Container(
            width: innerSize,
            height: innerSize,
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
              color: item.isUnlocked ? null : theme.colorScheme.surfaceContainerHighest,
              boxShadow: boxShadows,
            ),
            child: Icon(
              iconForId(item.id),
              size: size * 32 / 72,
              color: item.isUnlocked
                  ? primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );

    if (!item.isUnlocked) {
      iconContent = ColorFiltered(colorFilter: _grayscaleFilter, child: iconContent);
    }

    return iconContent;
  }
}
