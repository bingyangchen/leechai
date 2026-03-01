import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class CategoryMonthlyBarChart extends StatelessWidget {
  const CategoryMonthlyBarChart({
    super.key,
    required this.monthlyTotals,
    required this.dateRange,
    required this.color,
    required this.privacyMode,
  });

  final List<({DateTime month, double amount})> monthlyTotals;
  final DateRange dateRange;
  final Color color;
  final bool privacyMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawMax = monthlyTotals.isEmpty
        ? 1.0
        : monthlyTotals
              .map((e) => e.amount)
              .reduce((a, b) => a > b ? a : b)
              .clamp(1.0, double.infinity);
    final maxY = rawMax * 1.15;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                direction: TooltipDirection.bottom,
                getTooltipColor: (BarChartGroupData group) =>
                    theme.colorScheme.surfaceContainerHighest,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final d = monthlyTotals[group.x.toInt()];
                  final style =
                      theme.textTheme.bodySmall ??
                      theme.textTheme.bodyMedium ??
                      const TextStyle();
                  return BarTooltipItem(
                    '${d.month.year}/${d.month.month.toString().padLeft(2, '0')}\n\$${privacyMode ? "****" : formatAmountForDisplay(d.amount)}',
                    style,
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= monthlyTotals.length) {
                      return const SizedBox.shrink();
                    }
                    final d = monthlyTotals[i].month;
                    final label = d.month == 1
                        ? '${d.year.toString().substring(2)}年\n${d.month}月'
                        : '${d.month}月';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (v) => FlLine(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
                strokeWidth: 1,
              ),
            ),
            barGroups: monthlyTotals.asMap().entries.map((e) {
              final i = e.key;
              final d = e.value;
              final inRange = dateRange.containsMonth(d.month);
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: d.amount,
                    color: inRange ? color : color.withValues(alpha: 0.25),
                    width: inRange ? 14 : 10,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
                showingTooltipIndicators: [],
              );
            }).toList(),
          ),
          duration: const Duration(milliseconds: 200),
        ),
      ),
    );
  }
}
