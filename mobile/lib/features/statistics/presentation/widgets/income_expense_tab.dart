import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
import 'package:mobile/features/statistics/data/services/statistics.dart';
import 'package:mobile/features/statistics/domain/category_breakdown_item.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/features/statistics/presentation/constants/category_colors.dart';
import 'package:mobile/features/statistics/presentation/pages/category_detail_page.dart';
import 'package:mobile/features/statistics/presentation/widgets/category_donut_chart.dart';
import 'package:mobile/features/statistics/presentation/widgets/category_ranking_tile.dart';
import 'package:mobile/shared/widgets/haptic_refresh_wrapper.dart';

class IncomeExpenseTab extends StatefulWidget {
  const IncomeExpenseTab({
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
  State<IncomeExpenseTab> createState() => _IncomeExpenseTabState();
}

class _IncomeExpenseTabState extends State<IncomeExpenseTab> {
  bool _isExpense = true;
  int? _touchedIndex;
  late Future<_TabData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    widget.refreshTrigger?.addListener(_onRefreshTrigger);
  }

  @override
  void didUpdateWidget(IncomeExpenseTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefreshTrigger);
      widget.refreshTrigger?.addListener(_onRefreshTrigger);
    }
    if (oldWidget.dateRange.start != widget.dateRange.start ||
        oldWidget.dateRange.end != widget.dateRange.end ||
        oldWidget.privacyMode != widget.privacyMode) {
      _future = _loadData();
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTrigger);
    super.dispose();
  }

  void _onRefreshTrigger() {
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

  void _onSegmentChanged(bool isExpense) {
    if (_isExpense != isExpense) {
      setState(() {
        _isExpense = isExpense;
        _touchedIndex = null;
        _future = _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _future = _loadData();
        });
        await _future;
      },
      child: HapticRefreshWrapper(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: _buildSegmentedControl(context),
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
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Text(
                          '錯誤：${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
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
      ),
    );
  }

  Widget _buildSegmentedControl(BuildContext context) {
    final theme = Theme.of(context);
    final expenseColor = EntryTypeColors.forType(context, EntryType.expense);
    final incomeColor = EntryTypeColors.forType(context, EntryType.income);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const margin = 4.0;
          final segmentWidth = constraints.maxWidth / 2;
          final indicatorLeft = margin + (_isExpense ? 0 : 1) * segmentWidth;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: indicatorLeft,
                top: margin,
                bottom: margin,
                width: segmentWidth - margin * 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _SlidingSegmentOption(
                      label: '支出',
                      selected: _isExpense,
                      activeColor: expenseColor,
                      onTap: () => _onSegmentChanged(true),
                    ),
                  ),
                  Expanded(
                    child: _SlidingSegmentOption(
                      label: '收入',
                      selected: !_isExpense,
                      activeColor: incomeColor,
                      onTap: () => _onSegmentChanged(false),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
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
        final color = colorForSubType(context, item.subType, index);
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
            if (mounted) {
              setState(() {
                _future = _loadData();
              });
            }
          },
        );
      },
    );
  }
}

class _SlidingSegmentOption extends StatefulWidget {
  const _SlidingSegmentOption({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  State<_SlidingSegmentOption> createState() => _SlidingSegmentOptionState();
}

class _SlidingSegmentOptionState extends State<_SlidingSegmentOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.selected
        ? widget.activeColor
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: theme.textTheme.labelLarge!.copyWith(
              color: color,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(widget.label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class _TabData {
  _TabData({required this.breakdown, required this.total});

  final List<CategoryBreakdownItem> breakdown;
  final double total;
}
