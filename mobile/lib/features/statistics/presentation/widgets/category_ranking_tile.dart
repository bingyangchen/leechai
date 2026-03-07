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
    final colorScheme = Theme.of(context).colorScheme;
    final appTextStyles = AppTextStyles.of(context);
    final amountStr = widget.privacyMode
        ? '****'
        : formatAmountForDisplay(widget.amount);
    final percentStr = '${widget.percent.toStringAsFixed(1)}%';

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
                  color: widget.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              title: Text(widget.subType),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(amountStr, style: appTextStyles.titleSmallEmphasis),
                      Text(percentStr, style: appTextStyles.bodySmallMuted),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
}
