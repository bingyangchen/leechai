import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/profile/domain/achievement_definitions.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_badge_graphics.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';

final _integerFormat = NumberFormat('#,##0');

bool _hasNavigationTarget(AchievementItem item) {
  return item.id == AchievementId.firstEntry.key ||
      item.id == AchievementId.firstIncome.key;
}

bool _hasActionArea(AchievementItem item) {
  return item.isUnlocked || _hasNavigationTarget(item);
}

Future<bool?> showAchievementDetailSheet(BuildContext context, AchievementItem item) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textStyles = theme.textStyles;
  final bottomPadding = 20 + MediaQuery.paddingOf(context).bottom;

  return showAppBottomSheet<bool>(
    context,
    title: null,
    titleAlignment: AppBottomSheetTitleAlignment.left,
    mode: AppBottomSheetMode.static,
    builder: (context) {
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroSection(item: item),
              const SizedBox(height: 16),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: textStyles.bodyLarge.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              if (item.target > 0 && !item.isUnlocked) ...[
                const SizedBox(height: 24),
                _ProgressSection(item: item),
              ],
              const SizedBox(height: 24),
              _ConditionCard(
                conditionText: item.isSecret && !item.isUnlocked
                    ? '解鎖後揭曉'
                    : item.conditionText,
              ),
              if (_hasActionArea(item)) const SizedBox(height: 32),
              _ActionArea(item: item),
            ],
          ),
        ),
      );
    },
  );
}

class _HeroSection extends StatefulWidget {
  const _HeroSection({required this.item});

  final AchievementItem item;

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: AchievementBadgeGraphics(
              size: 120,
              item: widget.item,
              showProgressRing: false,
              glow: widget.item.isUnlocked,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          widget.item.name,
          textAlign: TextAlign.center,
          style: textStyles.headlineSmallEmphasis.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: widget.item.isUnlocked
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.item.isUnlocked && widget.item.unlockedAt != null
                    ? '解鎖於 ${DateFormat('y/MM/dd').format(widget.item.unlockedAt!)}'
                    : '尚未解鎖',
                style: textStyles.labelSmallMuted.copyWith(
                  color: widget.item.isUnlocked
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressSection extends StatefulWidget {
  const _ProgressSection({required this.item});

  final AchievementItem item;

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _progress = Tween<double>(begin: 0, end: widget.item.progress.clamp(0.0, 1.0))
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.27, 1.0, curve: Curves.easeOut),
          ),
        );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text.rich(
            TextSpan(
              text: '目前進度：',
              style: theme.textStyles.labelMuted,
              children: [
                TextSpan(
                  text:
                      '${_integerFormat.format(widget.item.current)} / ${_integerFormat.format(widget.item.target)}',
                  style: theme.textStyles.labelEmphasis.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedBuilder(
                animation: _progress,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: _progress.value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FractionallySizedBox extends StatelessWidget {
  const FractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
  });

  final double widthFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(width: constraints.maxWidth * widthFactor, child: child);
      },
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({required this.conditionText});

  final String conditionText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '取得條件',
                style: textStyles.labelEmphasis.copyWith(color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(conditionText, style: textStyles.body),
        ],
      ),
    );
  }
}

class _ActionArea extends StatelessWidget {
  const _ActionArea({required this.item});

  final AchievementItem item;

  @override
  Widget build(BuildContext context) {
    if (item.isUnlocked) {
      // TODO: Implement the share achievement logic
      return FilledButton.tonal(onPressed: null, child: const Text('分享成就'));
    }
    if (_hasNavigationTarget(item)) {
      return FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('前往完成任務'),
      );
    }
    return const SizedBox.shrink();
  }
}
