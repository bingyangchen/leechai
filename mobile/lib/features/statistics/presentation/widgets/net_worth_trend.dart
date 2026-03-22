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
        final assetChange = latest.totalAssets - first.totalAssets;
        final liabilityChange = latest.totalLiabilities - first.totalLiabilities;

        final chartHeight = (MediaQuery.of(context).size.height * 0.35).clamp(
          200.0,
          360.0,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroMetrics(context, latest.netWorth, netChange),
            const SizedBox(height: 24),
            SizedBox(
              height: chartHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: NetWorthLineChart(data: data, privacyMode: widget.privacyMode),
              ),
            ),
            const SizedBox(height: 24),
            _buildChangeBreakdown(context, assetChange, liabilityChange),
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

  Widget _buildHeroMetrics(BuildContext context, double netWorth, double netChange) {
    final theme = Theme.of(context);
    final netStr = widget.privacyMode ? '****' : formatAmountForDisplay(netWorth);
    final changeStr = widget.privacyMode
        ? '****'
        : (netChange >= 0
              ? '+\$${formatAmountForDisplay(netChange)}'
              : '-\$${formatAmountForDisplay(-netChange)}');
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
              Text(
                '區間淨變化 $changeStr',
                style: theme.textStyles.bodyMuted.copyWith(
                  color: changeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeBreakdown(
    BuildContext context,
    double assetChange,
    double liabilityChange,
  ) {
    final theme = Theme.of(context);
    final incomeColor = AccountingColors.of(context).income;
    final assetStr = widget.privacyMode
        ? '****'
        : (assetChange >= 0
              ? '+\$${formatAmountForDisplay(assetChange)}'
              : '-\$${formatAmountForDisplay(-assetChange)}');
    final liabilityStr = widget.privacyMode
        ? '****'
        : (liabilityChange >= 0
              ? '+\$${formatAmountForDisplay(liabilityChange)}'
              : '-\$${formatAmountForDisplay(-liabilityChange)}');
    final assetValueColor = assetChange >= 0 ? incomeColor : theme.colorScheme.error;
    final liabilityValueColor = liabilityChange >= 0
        ? theme.colorScheme.error
        : incomeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildChangeBreakdownRow(
                context,
                leading: '總資產',
                value: assetStr,
                valueColor: assetValueColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, thickness: 1, color: theme.dividerColor),
              ),
              _buildChangeBreakdownRow(
                context,
                leading: '總負債',
                value: liabilityStr,
                valueColor: liabilityValueColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeBreakdownRow(
    BuildContext context, {
    required String leading,
    required String value,
    required Color valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(leading, style: theme.textStyles.bodyMuted)),
        Text(
          value,
          style: theme.textStyles.titleSmallEmphasis.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
