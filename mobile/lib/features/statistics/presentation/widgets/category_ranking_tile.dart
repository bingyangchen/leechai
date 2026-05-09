import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class CategoryRankingTile extends StatefulWidget {
  const CategoryRankingTile({
    super.key,
    required this.subType,
    required this.amount,
    required this.percent,
    required this.icon,
    required this.color,
    required this.privacyMode,
    required this.onTap,
  });

  final String subType;
  final double amount;
  final double percent;
  final IconData icon;
  final Color color;
  final bool privacyMode;
  final VoidCallback onTap;

  @override
  State<CategoryRankingTile> createState() => _CategoryRankingTileState();
}

class _CategoryRankingTileState extends State<CategoryRankingTile> {
  double _previousPercent = 0;

  @override
  void didUpdateWidget(covariant CategoryRankingTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _previousPercent = oldWidget.percent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountStr = widget.privacyMode
        ? '****'
        : formatAmountForDisplay(widget.amount);
    final percentStr = '${widget.percent.toStringAsFixed(1)}%';
    final iconColor = _iconColor(theme);

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Stack(
          children: [
            Positioned(
              left: 56,
              right: 16,
              bottom: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        key: ValueKey(widget.percent),
                        tween: Tween(begin: _previousPercent, end: widget.percent),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => SizedBox(
                          width: constraints.maxWidth * (value / 100),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: iconColor, size: 22),
              ),
              title: Text(widget.subType),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(amountStr, style: theme.textStyles.titleSmallEmphasis),
                      Text(percentStr, style: theme.textStyles.bodySmallMuted),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _iconColor(ThemeData theme) {
    if (theme.brightness == Brightness.dark) return widget.color;

    final hsl = HSLColor.fromColor(widget.color);
    return hsl
        .withSaturation((hsl.saturation + 0.08).clamp(0.0, 1.0))
        .withLightness((hsl.lightness - 0.10).clamp(0.20, 0.55))
        .toColor();
  }
}
