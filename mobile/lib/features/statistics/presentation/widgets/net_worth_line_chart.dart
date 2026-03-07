import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/net_worth_snapshot.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class NetWorthLineChart extends StatelessWidget {
  const NetWorthLineChart({super.key, required this.data, required this.privacyMode});

  final List<NetWorthSnapshot> data;
  final bool privacyMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (data.isEmpty || data.length == 1) {
      return Center(
        child: Text(
          '資料不足',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.netWorth);
    }).toList();

    final dataMinY = data.map((s) => s.netWorth).reduce((a, b) => a < b ? a : b);
    final dataMaxY = data.map((s) => s.netWorth).reduce((a, b) => a > b ? a : b);
    final range = (dataMaxY - dataMinY).clamp(1.0, double.infinity);
    final axisMinY = dataMinY - range * 0.05;
    final axisMaxY = dataMaxY + range * 0.05;

    final xLabels = <int, String>{};
    final step = (data.length / 5).floor().clamp(1, data.length);
    for (var i = 0; i < data.length; i += step) {
      final d = data[i].date;
      xLabels[i] = '${d.month}月';
    }
    if (data.isNotEmpty && !xLabels.containsKey(data.length - 1)) {
      final d = data.last.date;
      xLabels[data.length - 1] = '${d.month}月';
    }

    String formatScaled(double scaled, String suffix) {
      final abs = scaled.abs();
      final sign = scaled < 0 ? '-' : '';
      if (abs >= 100) return '$sign${scaled.round()}$suffix';
      if (abs == abs.roundToDouble()) return '$sign${scaled.round()}$suffix';
      final s = abs.toStringAsFixed(1);
      return '$sign${s.endsWith('.0') ? abs.toInt() : s}$suffix';
    }

    String formatY(double v) {
      if (privacyMode) return '****';
      final abs = v.abs();
      if (abs >= 1000000000) return formatScaled(v / 1000000000, 'T');
      if (abs >= 1000000) return formatScaled(v / 1000000, 'M');
      if (abs >= 1000) return formatScaled(v / 1000, 'K');
      return v.round().toString();
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: range / 4,
              getTitlesWidget: (v, meta) {
                final nearBottom = (v - axisMinY).abs() < range * 0.02;
                final nearTop = (axisMaxY - v).abs() < range * 0.02;
                if (nearBottom || nearTop) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    formatY(v),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: step.toDouble(),
              getTitlesWidget: (v, meta) {
                final i = v.round().clamp(0, data.length - 1);
                if (i == data.length - 1) return const SizedBox.shrink();

                final label = xLabels[i] ?? '';
                if (label.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
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
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
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
            getTooltipItems: (spots) {
              return spots.map((s) {
                final i = s.x.toInt();
                if (i < 0 || i >= data.length) return null;
                final d = data[i].date;
                final val = privacyMode
                    ? '****'
                    : formatAmountForDisplay(data[i].netWorth);
                final style = theme.textTheme.bodySmall;
                if (style == null) return null;
                final dateStr =
                    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
                return LineTooltipItem('$dateStr\n\$$val', style);
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primary.withValues(alpha: 0.35),
                  primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 200),
    );
  }
}
