import 'package:flutter/material.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class UserStatsCardFront extends StatelessWidget {
  const UserStatsCardFront({
    super.key,
    required this.data,
    required this.entranceT,
    required this.theme,
    required this.heroColors,
    required this.gradient,
    required this.edgeColor,
    required this.thicknessOffset,
    required this.glossCenterX,
    required this.glossCenterY,
  });

  final ProfilePageData data;
  final double entranceT;
  final ThemeData theme;
  final HeroCardColors heroColors;
  final Gradient gradient;
  final Color edgeColor;
  final Offset thicknessOffset;
  final double glossCenterX;
  final double glossCenterY;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: thicknessOffset,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: edgeColor,
              ),
            ),
          ),
        ),
        Container(
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
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: _HeroStreakBlock(
                          value: '${(data.consecutiveActiveDays * entranceT).round()}',
                          label: '連續活躍日',
                          progressFactor: entranceT,
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
                                    value: '${(data.totalEntries * entranceT).round()}',
                                    label: '總記帳數',
                                    contentColor: heroColors.content,
                                    contentColorMuted: heroColors.contentMuted,
                                  ),
                                ),
                                Expanded(
                                  child: _AuxStatBlock(
                                    icon: Icons.calendar_today,
                                    value: '${(data.totalDays * entranceT).round()}',
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
                                    progressFactor: entranceT,
                                    contentColor: heroColors.content,
                                    contentColorMuted: heroColors.contentMuted,
                                  ),
                                ),
                                Expanded(
                                  child: _AuxStatBlock(
                                    icon: Icons.bar_chart,
                                    value:
                                        '${(data.entriesThisMonth * entranceT).round()}',
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
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(
                      center: Alignment(
                        glossCenterX.clamp(-1.0, 2.0),
                        glossCenterY.clamp(-1.0, 2.0),
                      ),
                      radius: 1.2,
                      colors: [
                        heroColors.content.withValues(alpha: 0.12),
                        heroColors.content.withValues(alpha: 0.04),
                        heroColors.content.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 12,
                child: _BrandMark(heroColors: heroColors),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.heroColors});

  final HeroCardColors heroColors;

  @override
  Widget build(BuildContext context) {
    final silver = heroColors.content.withValues(alpha: 0.62);
    return Text(
      'LEECHAI',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: silver,
      ),
    );
  }
}

class _HeroStreakBlock extends StatelessWidget {
  const _HeroStreakBlock({
    required this.value,
    required this.label,
    this.progressFactor = 1.0,
    required this.contentColor,
    required this.contentColorMuted,
  });

  final String value;
  final String label;
  final double progressFactor;
  final Color contentColor;
  final Color contentColorMuted;

  static const double _iconSize = 40;

  @override
  Widget build(BuildContext context) {
    final scale = Curves.easeOutBack.transform(progressFactor.clamp(0.0, 1.0));
    final opacity = progressFactor.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: Icon(
                Icons.local_fire_department,
                size: _iconSize,
                color: contentColor.withValues(alpha: opacity),
              ),
            ),
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
    this.progressFactor = 1.0,
    required this.contentColor,
    required this.contentColorMuted,
  });

  final int unlocked;
  final int total;
  final double progressFactor;
  final Color contentColor;
  final Color contentColorMuted;

  static const double _size = 40;
  static const double _strokeWidth = 2.5;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (unlocked / total).clamp(0.0, 1.0) : 0.0;
    final displayProgress = (progress * progressFactor).clamp(0.0, 1.0);
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
                value: displayProgress,
                strokeWidth: _strokeWidth,
                strokeCap: StrokeCap.round,
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
