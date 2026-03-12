import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/features/statistics/domain/net_worth_range.dart';
import 'package:mobile/features/statistics/presentation/widgets/date_range_picker_sheet.dart';
import 'package:mobile/features/statistics/presentation/widgets/income_expense_tab.dart';
import 'package:mobile/features/statistics/presentation/widgets/net_worth_tab.dart';
import 'package:mobile/shared/theme/app_theme.dart';

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

  Widget _buildTimeSelectorForCurrentTab() {
    final theme = Theme.of(context);
    if (_tabController.index == 0) {
      return Align(
        key: const ValueKey('date_btn'),
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _onDateRangeTap,
          icon: const Icon(Icons.calendar_month, size: 20),
          label: Text(
            _dateRange.toShortLabel(_preset),
            style: theme.textStyles.titleEmphasis,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      key: const ValueKey('chips'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NetWorthRange.values.map((r) {
          final selected = r == _netWorthRange;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(r.label),
              selected: selected,
              onSelected: (v) {
                if (v) {
                  setState(() => _netWorthRange = r);
                }
              },
              side: BorderSide(color: theme.colorScheme.outline),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _buildTimeSelectorForCurrentTab(),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _privacyMode = !_privacyMode),
                    style: IconButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.all(8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      _privacyMode
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 22,
                    ),
                    tooltip: _privacyMode ? '顯示金額' : '隱藏金額',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: theme.colorScheme.primaryContainer,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: theme.colorScheme.onPrimaryContainer,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: theme.textStyles.titleEmphasis,
                unselectedLabelStyle: theme.textStyles.title,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                tabs: const [
                  Tab(text: '收支結構'),
                  Tab(text: '資產趨勢'),
                ],
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
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
