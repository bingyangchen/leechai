import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/budget/presentation/pages/budget_page.dart';
import 'package:mobile/features/budget/presentation/widgets/budget_non_month_hint.dart';
import 'package:mobile/features/budget/presentation/widgets/budget_progress_card.dart';
import 'package:mobile/features/statistics/data/services/statistics.dart';
import 'package:mobile/features/statistics/domain/category_breakdown_item.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/features/statistics/presentation/constants/category_colors.dart';
import 'package:mobile/features/statistics/presentation/pages/category_detail_page.dart';
import 'package:mobile/features/statistics/presentation/widgets/category_donut_chart.dart';
import 'package:mobile/features/statistics/presentation/widgets/category_ranking_tile.dart';
import 'package:mobile/features/statistics/presentation/widgets/net_worth_trend.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/refresh_snap_back.dart';
import 'package:mobile/shared/widgets/app_refresh_indicator.dart';
import 'package:mobile/shared/widgets/haptic_refresh_wrapper.dart';
import 'package:mobile/shared/widgets/sliding_segmented_control.dart';

class StatisticsDashboardBody extends StatefulWidget {
  const StatisticsDashboardBody({
    super.key,
    required this.dateRange,
    this.preset,
    required this.onDateRangeChanged,
    required this.privacyMode,
    this.refreshTrigger,
    this.rankingAnimationTrigger = 0,
  });

  final DateRange dateRange;
  final DateRangePreset? preset;
  final void Function(DateRange range, DateRangePreset? preset) onDateRangeChanged;
  final bool privacyMode;
  final ValueListenable<int>? refreshTrigger;
  final int rankingAnimationTrigger;

  @override
  State<StatisticsDashboardBody> createState() => _StatisticsDashboardBodyState();
}

class _StatisticsDashboardBodyState extends State<StatisticsDashboardBody> {
  bool _isExpense = true;
  int? _touchedIndex;
  late Future<_TabData> _future;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    widget.refreshTrigger?.addListener(_onRefresh);
  }

  @override
  void didUpdateWidget(StatisticsDashboardBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefresh);
      widget.refreshTrigger?.addListener(_onRefresh);
    }
    if (oldWidget.dateRange.start != widget.dateRange.start ||
        oldWidget.dateRange.end != widget.dateRange.end ||
        oldWidget.privacyMode != widget.privacyMode) {
      _future = _loadData();
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

  Future<_TabData> _loadData() async {
    final breakdown = await StatisticsService.getCategoryBreakdown(
      widget.dateRange.start,
      widget.dateRange.end,
      _isExpense,
    );
    final totals = await StatisticsService.getRangeTotals(
      widget.dateRange.start,
      widget.dateRange.end,
    );
    return _TabData(
      breakdown: breakdown,
      total: _isExpense ? totals.totalExpense : totals.totalIncome,
    );
  }

  Widget _buildBudgetSection(BuildContext context) {
    final now = DateTime.now();
    final isThisMonth = widget.dateRange.isThisMonthView(now);
    if (!isThisMonth) {
      return BudgetNonMonthHint(
        onViewThisMonth: () => navigateDateRangeToThisMonth(widget.onDateRangeChanged),
      );
    }
    return BudgetProgressCard(
      privacyMode: widget.privacyMode,
      refreshTrigger: widget.refreshTrigger,
      rankingAnimationTrigger: widget.rankingAnimationTrigger,
      showTitleRow: false,
      onOpenSettings: () async {
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => BudgetPage(refreshTrigger: widget.refreshTrigger),
          ),
        );
        if (!context.mounted) return;
        if (saved == true) {
          (widget.refreshTrigger as ValueNotifier<int>?)?.value++;
          setState(() {
            _future = _loadData();
          });
        }
      },
    );
  }

  void _onSegmentChanged(bool isExpense) {
    if (_isExpense != isExpense) {
      setState(() {
        _isExpense = isExpense;
        _touchedIndex = null;
        _future = _loadData();
      });
    }
  }

  Widget _dashboardSectionTitle(
    BuildContext context,
    String title, {
    double topPadding = 0,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 10),
      child: Text(title, style: Theme.of(context).textStyles.sectionLabel),
    );
  }

  Widget _dashboardSectionHeader(
    BuildContext context,
    String title, {
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textStyles.sectionLabel),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }

  Widget _dashboardSectionDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
    );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dashboardSectionTitle(context, '淨值趨勢', topPadding: 8),
                NetWorthTrendSection(
                  dateRange: widget.dateRange,
                  privacyMode: widget.privacyMode,
                  refreshTrigger: widget.refreshTrigger,
                ),
                const SizedBox(height: 28),
                _dashboardSectionDivider(context),
                const SizedBox(height: 20),
                _dashboardSectionTitle(context, '本月預算'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildBudgetSection(context),
                ),
                const SizedBox(height: 28),
                _dashboardSectionDivider(context),
                const SizedBox(height: 20),
                _dashboardSectionHeader(
                  context,
                  '收支結構',
                  trailing: SizedBox(
                    width: 140,
                    child: _buildSegmentedControl(context),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<_TabData>(
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

                if (data.breakdown.isEmpty) {
                  return const CategoryChartEmptyState();
                }

                return Column(
                  children: [
                    CategoryDonutChart(
                      breakdown: data.breakdown,
                      total: data.total,
                      touchedIndex: _touchedIndex,
                      isExpense: _isExpense,
                      privacyMode: widget.privacyMode,
                      onSectionTouched: (i) {
                        setState(() => _touchedIndex = i);
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildRankingList(context, data),
                  ],
                );
              },
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(BuildContext context) {
    final theme = Theme.of(context);

    return SlidingSegmentedControl(
      segmentLabels: const ['支出', '收入'],
      selectedIndex: _isExpense ? 0 : 1,
      onSelected: (index) => _onSegmentChanged(index == 0),
      thumbDecoration: slidingSegmentElevatedThumb(context),
      selectedLabelColor: (_) => theme.colorScheme.onSurface,
      labelVerticalPadding: 7,
      labelStyle: theme.textStyles.labelEmphasis,
    );
  }

  Widget _buildRankingList(BuildContext context, _TabData data) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: data.breakdown.length,
      itemBuilder: (context, index) {
        final item = data.breakdown[index];
        final color = colorForCategoryIndex(context, index);
        return CategoryRankingTile(
          key: ValueKey('${widget.rankingAnimationTrigger}-${item.subType}'),
          subType: item.subType,
          amount: item.amount,
          percent: item.percent,
          icon: item.icon,
          color: color,
          privacyMode: widget.privacyMode,
          onTap: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => CategoryDetailPage(
                  subType: item.subType,
                  isExpense: _isExpense,
                  dateRange: widget.dateRange,
                  privacyMode: widget.privacyMode,
                ),
              ),
            );
            if (mounted) _onRefresh();
          },
        );
      },
    );
  }
}

class _TabData {
  _TabData({required this.breakdown, required this.total});

  final List<CategoryBreakdownItem> breakdown;
  final double total;
}
