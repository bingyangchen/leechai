import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/category_breakdown_item.dart';
import 'package:mobile/features/statistics/presentation/constants/category_colors.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.breakdown,
    required this.total,
    required this.touchedIndex,
    required this.isExpense,
    required this.privacyMode,
    required this.onSectionTouched,
  });

  final List<CategoryBreakdownItem> breakdown;
  final double total;
  final int? touchedIndex;
  final bool isExpense;
  final bool privacyMode;
  final void Function(int?) onSectionTouched;

  @override
  Widget build(BuildContext context) {
    final appTextStyles = AppTextStyles.of(context);
    final displayAmount = privacyMode ? '****' : formatAmountForDisplay(total);
    final touched = touchedIndex;
    final isValidTouched =
        touched != null && touched >= 0 && touched < breakdown.length;
    final displayLabel = isValidTouched
        ? breakdown[touched].subType
        : isExpense
        ? '總支出'
        : '總收入';

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  onSectionTouched(response?.touchedSection?.touchedSectionIndex);
                },
              ),
              sectionsSpace: 4,
              centerSpaceRadius: 70,
              sections: breakdown.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                final baseColor = colorForSubType(context, item.subType, i);
                final isTouched = isValidTouched && i == touched;
                final opacity = (isValidTouched && !isTouched) ? 0.3 : 1.0;
                return PieChartSectionData(
                  value: item.amount,
                  title: '',
                  color: baseColor.withValues(alpha: opacity),
                  radius: isTouched ? 32 : 24,
                  badgePositionPercentageOffset: 0,
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 200),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayLabel,
                style: appTextStyles.bodySmallMuted,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isValidTouched
                      ? (privacyMode
                            ? '****'
                            : formatAmountForDisplay(breakdown[touched].amount))
                      : displayAmount,
                  style: appTextStyles.titleLargeEmphasis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryChartEmptyState extends StatelessWidget {
  const CategoryChartEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTextStyles = AppTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _EmptyDonutPainter(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('尚無紀錄', style: appTextStyles.titleMuted),
        ],
      ),
    );
  }
}

class _EmptyDonutPainter extends CustomPainter {
  _EmptyDonutPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final strokeWidth = 12.0;
    canvas.drawCircle(
      center,
      radius - strokeWidth / 2,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _EmptyDonutPainter old) => old.color != color;
}
