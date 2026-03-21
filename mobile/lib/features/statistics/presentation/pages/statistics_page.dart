import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/features/statistics/domain/net_worth_range.dart';
import 'package:mobile/features/statistics/presentation/widgets/date_range_picker_sheet.dart';
import 'package:mobile/features/statistics/presentation/widgets/income_expense_tab.dart';
import 'package:mobile/features/statistics/presentation/widgets/net_worth_tab.dart';
import 'package:mobile/shared/theme/app_theme.dart';
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
            _StatisticsTopBar(
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

class _StatisticsTopBar extends StatelessWidget {
  const _StatisticsTopBar({
    required this.tabIndex,
    required this.dateRange,
    required this.preset,
    required this.onDateRangeTap,
    required this.netWorthRange,
    required this.onNetWorthRangeSelected,
    required this.privacyMode,
    required this.onPrivacyModeToggle,
  });

  final int tabIndex;
  final DateRange dateRange;
  final DateRangePreset? preset;
  final Future<void> Function() onDateRangeTap;
  final NetWorthRange netWorthRange;
  final ValueChanged<NetWorthRange> onNetWorthRangeSelected;
  final bool privacyMode;
  final VoidCallback onPrivacyModeToggle;

  Widget _timeSelector(BuildContext context) {
    final theme = Theme.of(context);
    if (tabIndex == 0) {
      return Align(
        key: const ValueKey('date_btn'),
        alignment: Alignment.centerLeft,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onDateRangeTap(),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateRange.toShortLabel(preset),
                    style: theme.textStyles.titleEmphasis,
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Align(
      key: const ValueKey('chips'),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: NetWorthRange.values.map((range) {
            final selected = range == netWorthRange;
            final outlineGhost = theme.colorScheme.outline.withValues(alpha: 0.22);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                showCheckmark: false,
                label: Text(range.label),
                labelStyle: selected
                    ? theme.textStyles.titleSmallEmphasis.copyWith(
                        color: theme.colorScheme.onPrimary,
                      )
                    : theme.textStyles.sectionLabel.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.85,
                        ),
                        fontWeight: FontWeight.w400,
                      ),
                selected: selected,
                onSelected: (selectedValue) {
                  if (selectedValue) {
                    onNetWorthRangeSelected(range);
                  }
                },
                color: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.colorScheme.primary;
                  }
                  return theme.colorScheme.surface.withValues(alpha: 0);
                }),
                side: WidgetStateBorderSide.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return BorderSide(color: theme.colorScheme.primary);
                  }
                  return BorderSide(color: outlineGhost);
                }),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: AppTheme.topBarControlSlotHeight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
                child: _timeSelector(context),
              ),
            ),
          ),
          IconButton(
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              fixedSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              privacyMode ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: privacyMode
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: onPrivacyModeToggle,
            tooltip: privacyMode ? '關閉隱私模式' : '隱私模式',
          ),
        ],
      ),
    );
  }
}
