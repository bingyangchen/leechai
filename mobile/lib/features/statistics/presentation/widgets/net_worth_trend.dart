import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/data/services/statistics.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/features/statistics/domain/net_worth_snapshot.dart';
import 'package:mobile/features/statistics/presentation/widgets/net_worth_line_chart.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class NetWorthTrendSection extends StatefulWidget {
  const NetWorthTrendSection({
    super.key,
    required this.dateRange,
    required this.privacyMode,
    this.refreshTrigger,
  });

  final DateRange dateRange;
  final bool privacyMode;
  final ValueListenable<int>? refreshTrigger;

  @override
  State<NetWorthTrendSection> createState() => _NetWorthTrendSectionState();
}

class _NetWorthTrendSectionState extends State<NetWorthTrendSection> {
  late Future<List<NetWorthSnapshot>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    widget.refreshTrigger?.addListener(_onRefresh);
  }

  @override
  void didUpdateWidget(NetWorthTrendSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefresh);
      widget.refreshTrigger?.addListener(_onRefresh);
    }
    if (oldWidget.dateRange.start != widget.dateRange.start ||
        oldWidget.dateRange.end != widget.dateRange.end ||
        oldWidget.privacyMode != widget.privacyMode) {
      _future = _loadData();
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<List<NetWorthSnapshot>> _loadData() async {
    return StatisticsService.getNetWorthHistory(
      widget.dateRange.start,
      widget.dateRange.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NetWorthSnapshot>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        if (data.isEmpty) {
          return _buildEmptyState(context);
        }

        final latest = data.last;
        final first = data.first;
        final netChange = latest.netWorth - first.netWorth;

        final chartHeight = (MediaQuery.of(context).size.height * 0.35).clamp(
          200.0,
          360.0,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroMetrics(context, latest.netWorth, netChange, first.netWorth),
            const SizedBox(height: 24),
            SizedBox(
              height: chartHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: NetWorthLineChart(data: data, privacyMode: widget.privacyMode),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(
            Icons.show_chart_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('尚無資料', style: theme.textStyles.titleMuted),
          const SizedBox(height: 8),
          Text(
            '新增記帳後即可查看淨值趨勢',
            style: theme.textStyles.bodySmallMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetrics(
    BuildContext context,
    double netWorth,
    double netChange,
    double baselineNetWorth,
  ) {
    final theme = Theme.of(context);
    final netStr = widget.privacyMode ? '****' : formatAmountForDisplay(netWorth);
    final amountChangeStr = widget.privacyMode
        ? '****'
        : (netChange >= 0
              ? '+\$${formatAmountForDisplay(netChange)}'
              : '-\$${formatAmountForDisplay(-netChange)}');
    final changePercentStr = widget.privacyMode || baselineNetWorth.abs() < 0.01
        ? null
        : _formatPercentChange(netChange / baselineNetWorth.abs() * 100);
    final changeStr = changePercentStr == null
        ? amountChangeStr
        : '$amountChangeStr ($changePercentStr)';
    final accountingColors = AccountingColors.of(context);
    final changeColor = netChange >= 0
        ? accountingColors.income
        : theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\$$netStr', style: theme.textStyles.headlineEmphasis),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                netChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: changeColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '區間淨變化 $changeStr',
                  style: theme.textStyles.bodyMuted.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatPercentChange(double percent) {
  final absPercent = percent.abs();
  final digits = absPercent >= 100 ? 0 : 1;
  final value = absPercent.toStringAsFixed(digits).replaceFirst(RegExp(r'\.0$'), '');
  final sign = percent >= 0 ? '+' : '-';
  return '$sign$value%';
}
