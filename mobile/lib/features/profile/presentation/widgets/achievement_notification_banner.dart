import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_badge_graphics.dart';
import 'package:mobile/shared/theme/app_theme.dart';

const _autoDismissDuration = Duration(seconds: 4);
const _topSpacing = 8.0;

class AchievementNotificationBanner extends StatefulWidget {
  const AchievementNotificationBanner({
    super.key,
    required this.item,
    required this.onDismiss,
  });

  final AchievementItem item;
  final VoidCallback onDismiss;

  @override
  State<AchievementNotificationBanner> createState() =>
      _AchievementNotificationBannerState();
}

class _AchievementNotificationBannerState extends State<AchievementNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacity = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    HapticFeedback.mediumImpact();
    Future.delayed(_autoDismissDuration, () {
      if (mounted) _dismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;
    final topPadding = MediaQuery.paddingOf(context).top;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: topPadding + _topSpacing),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Dismissible(
                    key: ValueKey(widget.item.id),
                    direction: DismissDirection.up,
                    onDismissed: (_) => widget.onDismiss(),
                    child: Material(
                      color: colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
                      child: InkWell(
                        onTap: _dismiss,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AchievementBadgeGraphics(
                                size: 40,
                                item: widget.item,
                                showProgressRing: false,
                                glow: true,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('成就解鎖', style: textStyles.labelSmallMuted),
                                    const SizedBox(height: 1),
                                    Text(
                                      widget.item.name,
                                      style: textStyles.titleSmallEmphasis,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
