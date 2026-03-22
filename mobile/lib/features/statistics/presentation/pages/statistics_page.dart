import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/features/statistics/domain/net_worth_range.dart';
import 'package:mobile/features/statistics/presentation/widgets/date_range_picker_sheet.dart';
import 'package:mobile/features/statistics/presentation/widgets/income_expense_tab.dart';
import 'package:mobile/features/statistics/presentation/widgets/net_worth_tab.dart';
import 'package:mobile/features/statistics/presentation/widgets/statistics_top_bar.dart';
import 'package:mobile/shared/widgets/sliding_segmented_control.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, this.refreshTrigger, this.isPageVisible = false});

  final ValueListenable<int>? refreshTrigger;
  final bool isPageVisible;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _privacyMode = false;
  late DateRange _dateRange;
  DateRangePreset? _preset;
  NetWorthRange _netWorthRange = NetWorthRange.sixMonths;
  int _rankingAnimationTrigger = 0;
  int _prevTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _dateRange = DateRange.forPreset(DateRangePreset.thisMonth, DateTime.now());
    _preset = DateRangePreset.thisMonth;
    widget.refreshTrigger?.addListener(_onRefresh);
  }

  void _onTabChanged() {
    final idx = _tabController.index;
    if (_prevTabIndex != idx && idx == 0) {
      setState(() {
        _rankingAnimationTrigger++;
        _prevTabIndex = idx;
      });
    } else {
      setState(() => _prevTabIndex = idx);
    }
  }

  @override
  void didUpdateWidget(StatisticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefresh);
      widget.refreshTrigger?.addListener(_onRefresh);
    }
    if (!oldWidget.isPageVisible && widget.isPageVisible) {
      setState(() => _rankingAnimationTrigger++);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    widget.refreshTrigger?.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    setState(() {});
  }

  Future<void> _onDateRangeTap() async {
    final result = await showDateRangePickerSheet(
      context,
      initialRange: _dateRange,
      initialPreset: _preset,
    );
    if (result != null && mounted) {
      setState(() {
        _dateRange = result.range;
        _preset = result.preset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StatisticsTopBar(
              tabIndex: _tabController.index,
              dateRange: _dateRange,
              preset: _preset,
              onDateRangeTap: _onDateRangeTap,
              netWorthRange: _netWorthRange,
              onNetWorthRangeSelected: (range) =>
                  setState(() => _netWorthRange = range),
              privacyMode: _privacyMode,
              onPrivacyModeToggle: () => setState(() => _privacyMode = !_privacyMode),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return SlidingSegmentedControl(
                    segmentLabels: const ['收支結構', '資產趨勢'],
                    selectedIndex: _tabController.index,
                    onSelected: (index) {
                      if (_tabController.index != index) {
                        _tabController.animateTo(index);
                      }
                    },
                    thumbDecoration: slidingSegmentPrimaryThumb(context),
                    selectedLabelColor: (_) =>
                        Theme.of(context).colorScheme.onPrimaryContainer,
                  );
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  IncomeExpenseTab(
                    dateRange: _dateRange,
                    preset: _preset,
                    onDateRangeChanged: (range, preset) => setState(() {
                      _dateRange = range;
                      _preset = preset;
                    }),
                    privacyMode: _privacyMode,
                    refreshTrigger: widget.refreshTrigger,
                    rankingAnimationTrigger: _rankingAnimationTrigger,
                  ),
                  NetWorthTab(
                    range: _netWorthRange,
                    privacyMode: _privacyMode,
                    refreshTrigger: widget.refreshTrigger,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
