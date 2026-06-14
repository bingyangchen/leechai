import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class AccountBalanceChart extends StatelessWidget {
  const AccountBalanceChart({
    super.key,
    required this.history,
    required this.privacyMode,
  });

  final List<({DateTime date, double balance})> history;
  final bool privacyMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (history.length < 2) {
      return const SizedBox.shrink();
    }

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.balance);
    }).toList();

    final dataMinY = history.map((s) => s.balance).reduce((a, b) => a < b ? a : b);
    final dataMaxY = history.map((s) => s.balance).reduce((a, b) => a > b ? a : b);
    final range = (dataMaxY - dataMinY).clamp(1.0, double.infinity);
    final axisMinY = dataMinY - range * 0.1;
    final axisMaxY = dataMaxY + range * 0.1;

    return SizedBox(
      height: 100,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (history.length - 1).toDouble(),
          minY: axisMinY,
          maxY: axisMaxY,
          lineTouchData: LineTouchData(
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 4,
                          color: primary,
                          strokeWidth: 2,
                          strokeColor: theme.colorScheme.surface,
                        ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) {
                return spots.map((s) {
                  final i = s.x.toInt();
                  if (i < 0 || i >= history.length) return null;
                  final d = history[i].date;
                  final val = privacyMode
                      ? '****'
                      : formatAmountForDisplay(history[i].balance);
                  final dateStr =
                      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
                  return LineTooltipItem(
                    '$dateStr\n',
                    theme.textStyles.labelSmallMuted,
                    textAlign: TextAlign.start,
                    children: [
                      TextSpan(
                        text: '\$$val',
                        style:
                            (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: primary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primary.withValues(alpha: 0.2),
                    primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
