import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class UserStatsCard extends StatefulWidget {
  const UserStatsCard({
    super.key,
    required this.data,
    this.isPageVisible = true,
    this.interactionNotifier,
    this.onTap,
  });
  final ProfilePageData data;
  final bool isPageVisible;
  final ValueNotifier<bool>? interactionNotifier;
  final VoidCallback? onTap;

  @override
  State<UserStatsCard> createState() => _UserStatsCardState();
}

class _UserStatsCardState extends State<UserStatsCard> with TickerProviderStateMixin {
  double _tiltX = 0;
  double _tiltY = 0;
  Offset? _lastPosition;
  Offset? _pointerDownPosition;
  static const double _maxTilt = 0.12;
  static const double _tapSlop = 18;
  static const double _dragSensitivity = 0.003;
  static const int _springBackDurationMs = 200;
  static const int _entranceDurationMs = 1000;

  late AnimationController _springController;
  late AnimationController _entranceController;
  double _tiltXBeforeSpring = 0;
  double _tiltYBeforeSpring = 0;
  bool _wasPageVisible = false;

  void _runEntranceAnimation() {
    if (!mounted) return;
    _entranceController.reset();
    _entranceController.forward();
  }

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _springBackDurationMs),
    );
    _springController.addListener(_onSpringTick);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _entranceDurationMs),
    );
    _entranceController.addListener(() => setState(() {}));
    _wasPageVisible = widget.isPageVisible;
    if (widget.isPageVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runEntranceAnimation());
    }
  }

  @override
  void didUpdateWidget(UserStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPageVisible && !_wasPageVisible) {
      _runEntranceAnimation();
      _wasPageVisible = true;
    } else if (!widget.isPageVisible) {
      _wasPageVisible = false;
    }
  }

  void _onSpringTick() {
    if (!_springController.isAnimating) return;
    final value = Curves.easeOut.transform(_springController.value);
    setState(() {
      _tiltX = ui.lerpDouble(_tiltXBeforeSpring, 0, value)!;
      _tiltY = ui.lerpDouble(_tiltYBeforeSpring, 0, value)!;
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _lastPosition = event.position;
    _pointerDownPosition = event.position;
    _springController.stop();
    widget.interactionNotifier?.value = true;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_lastPosition == null) return;
    final delta = event.position - _lastPosition!;
    _lastPosition = event.position;
    setState(() {
      _tiltY -= delta.dx * _dragSensitivity;
      _tiltX += delta.dy * _dragSensitivity;
      _tiltX = _tiltX.clamp(-_maxTilt, _maxTilt);
      _tiltY = _tiltY.clamp(-_maxTilt, _maxTilt);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    final down = _pointerDownPosition;
    _lastPosition = null;
    _pointerDownPosition = null;
    widget.interactionNotifier?.value = false;
    if (down != null &&
        widget.onTap != null &&
        (event.position - down).distance <= _tapSlop) {
      widget.onTap!();
    }
    _tiltXBeforeSpring = _tiltX;
    _tiltYBeforeSpring = _tiltY;
    _springController.forward(from: 0);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _lastPosition = null;
    _pointerDownPosition = null;
    widget.interactionNotifier?.value = false;
    _tiltXBeforeSpring = _tiltX;
    _tiltYBeforeSpring = _tiltY;
    _springController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final entranceT = Curves.easeOut.transform(_entranceController.value);
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

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(_tiltX)
      ..rotateY(_tiltY);

    final glossCenterX = 0.5 + _tiltY * 2.5;
    final glossCenterY = 0.5 + _tiltX * 2.5;

    const double cardAspectRatio = 85.6 / 53.98;
    const double thicknessPixels = 8;
    final thicknessOffset = Offset(thicknessPixels * _tiltY, -thicknessPixels * _tiltX);
    final edgeColor = isDark
        ? theme.colorScheme.surface.withValues(alpha: 0.5)
        : theme.colorScheme.primary.withValues(alpha: 0.55);

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: AspectRatio(
          aspectRatio: cardAspectRatio,
          child: Transform(
            alignment: Alignment.center,
            transform: transform,
            child: Stack(
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 20,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: _HeroStreakBlock(
                                  value:
                                      '${(widget.data.consecutiveActiveDays * entranceT).round()}',
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
                                            value:
                                                '${(widget.data.totalEntries * entranceT).round()}',
                                            label: '總記帳數',
                                            contentColor: heroColors.content,
                                            contentColorMuted: heroColors.contentMuted,
                                          ),
                                        ),
                                        Expanded(
                                          child: _AuxStatBlock(
                                            icon: Icons.calendar_today,
                                            value:
                                                '${(widget.data.totalDays * entranceT).round()}',
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
                                            unlocked: widget.data.unlockedBadgesCount,
                                            total: widget.data.totalBadgesCount,
                                            progressFactor: entranceT,
                                            contentColor: heroColors.content,
                                            contentColorMuted: heroColors.contentMuted,
                                          ),
                                        ),
                                        Expanded(
                                          child: _AuxStatBlock(
                                            icon: Icons.bar_chart,
                                            value:
                                                '${(widget.data.entriesThisMonth * entranceT).round()}',
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
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.heroColors});

  final HeroCardColors heroColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = heroColors.contentMuted.withValues(alpha: 0.82);
    final shadowColor = theme.colorScheme.shadow.withValues(alpha: 0.22);
    final highlightColor = heroColors.content.withValues(alpha: 0.28);
    return Text(
      'LEECHAI',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: baseColor,
        shadows: [
          Shadow(offset: const Offset(1, 1), blurRadius: 0, color: shadowColor),
          Shadow(
            offset: const Offset(-0.6, -0.6),
            blurRadius: 0,
            color: highlightColor,
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
