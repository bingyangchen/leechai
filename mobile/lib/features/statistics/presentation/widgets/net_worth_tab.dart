import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/data/services/statistics.dart';
import 'package:mobile/features/statistics/domain/net_worth_range.dart';
import 'package:mobile/features/statistics/domain/net_worth_snapshot.dart';
import 'package:mobile/features/statistics/presentation/widgets/net_worth_line_chart.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/refresh_snap_back.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';
import 'package:mobile/shared/widgets/app_refresh_indicator.dart';
import 'package:mobile/shared/widgets/haptic_refresh_wrapper.dart';

class NetWorthTab extends StatefulWidget {
  const NetWorthTab({
    super.key,
    required this.range,
    required this.privacyMode,
    this.refreshTrigger,
  });

  final NetWorthRange range;
  final bool privacyMode;
  final ValueListenable<int>? refreshTrigger;

  @override
  State<NetWorthTab> createState() => _NetWorthTabState();
}

class _NetWorthTabState extends State<NetWorthTab> {
  late Future<List<NetWorthSnapshot>> _future;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    widget.refreshTrigger?.addListener(_onRefresh);
  }

  @override
  void didUpdateWidget(NetWorthTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefresh);
      widget.refreshTrigger?.addListener(_onRefresh);
    }
    if (oldWidget.range != widget.range ||
        oldWidget.privacyMode != widget.privacyMode) {
      _future = _loadData();
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefresh);
    _scrollController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<List<NetWorthSnapshot>> _loadData() async {
    final range = widget.range.dateRange;
    return StatisticsService.getNetWorthHistory(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    return HapticRefreshWrapper(
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          appSliverRefreshControl(
            onRefresh: () => runRefreshWithSnapBack(_scrollController, () async {
              // NOTE: placebo effect
              await Future.delayed(const Duration(milliseconds: 800));
              _onRefresh();
              await _future;
            }),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FutureBuilder<List<NetWorthSnapshot>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
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
                  final liabilityChange =
                      latest.totalLiabilities - first.totalLiabilities;

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
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: NetWorthLineChart(
                            data: data,
                            privacyMode: widget.privacyMode,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildChangeBreakdown(context, assetChange, liabilityChange),
                    ],
                  );
                },
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('當前總淨值', style: theme.textStyles.sectionLabel),
          const SizedBox(height: 4),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _BreakdownChip(
              label: '總資產變化',
              value: assetStr,
              valueColor: assetChange >= 0 ? incomeColor : theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BreakdownChip(
              label: '總負債變化',
              value: liabilityStr,
              valueColor: liabilityChange >= 0 ? theme.colorScheme.error : incomeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  const _BreakdownChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textStyles.bodySmallMuted),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textStyles.titleSmallEmphasis.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
