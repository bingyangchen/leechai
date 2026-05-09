import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/net_worth_snapshot.dart';
import 'package:mobile/shared/theme/app_theme.dart';
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
      return Center(child: Text('資料不足', style: theme.textStyles.bodyMuted));
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
                    privacyMode ? '****' : _formatCompactAxisValue(v),
                    style: theme.textStyles.labelSmallMuted,
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
                  child: Text(label, style: theme.textStyles.labelSmallMuted),
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
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) {
              return spots.map((s) {
                final i = s.x.toInt();
                if (i < 0 || i >= data.length) return null;
                final d = data[i].date;
                final val = privacyMode
                    ? '****'
                    : formatAmountForDisplay(data[i].netWorth);
                final dateStr =
                    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
                return LineTooltipItem(
                  '$dateStr\n\$$val',
                  theme.textStyles.bodySmallMuted,
                );
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
      duration: Duration.zero,
    );
  }
}

// Keeps axis labels compact within three visible digits: 1550 -> 1.55K, -1550 -> -1.6K.
String _formatCompactAxisValue(double value) {
  const units = [
    (divisor: 1000000000, suffix: 'T'),
    (divisor: 1000000, suffix: 'M'),
    (divisor: 1000, suffix: 'K'),
    (divisor: 1, suffix: ''),
  ];

  final abs = value.abs();
  final maxDigits = value < 0 ? 2 : 3;
  var unitIndex = units.indexWhere((unit) => abs >= unit.divisor);
  if (unitIndex == -1) unitIndex = units.length - 1;

  while (true) {
    final unit = units[unitIndex];
    final text = _formatWithDigitLimit(value / unit.divisor, maxDigits);
    if (_digitCount(text) <= maxDigits || unitIndex == 0) {
      return '$text${unit.suffix}';
    }

    unitIndex -= 1;
  }
}

String _formatWithDigitLimit(double value, int maxDigits) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  if (abs == 0) return '0';

  final integerDigits = abs >= 1 ? abs.floor().toString().length : 1;
  final decimalPlaces = (maxDigits - integerDigits).clamp(0, maxDigits);
  final rounded = decimalPlaces == 0
      ? abs.round().toString()
      : abs
            .toStringAsFixed(decimalPlaces)
            .replaceFirst(RegExp(r'\.0+$'), '')
            .replaceFirst(RegExp(r'(\.\d*[1-9])0+$'), r'$1');

  return '$sign$rounded';
}

int _digitCount(String value) {
  var count = 0;
  for (final codeUnit in value.codeUnits) {
    if (codeUnit >= 48 && codeUnit <= 57) count += 1;
  }
  return count;
}
