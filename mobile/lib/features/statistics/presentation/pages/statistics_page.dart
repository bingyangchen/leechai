import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/features/statistics/presentation/widgets/date_range_picker_sheet.dart';
import 'package:mobile/features/statistics/presentation/widgets/statistics_dashboard_body.dart';
import 'package:mobile/features/statistics/presentation/widgets/statistics_top_bar.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, this.refreshTrigger, this.isPageVisible = false});

  final ValueListenable<int>? refreshTrigger;
  final bool isPageVisible;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _privacyMode = false;
  late DateRange _dateRange;
  DateRangePreset? _preset;
  int _rankingAnimationTrigger = 0;

  @override
  void initState() {
    super.initState();
    _dateRange = DateRange.forPreset(DateRangePreset.thisMonth, DateTime.now());
    _preset = DateRangePreset.thisMonth;
    widget.refreshTrigger?.addListener(_onRefresh);
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
              dateRange: _dateRange,
              preset: _preset,
              onDateRangeTap: _onDateRangeTap,
              privacyMode: _privacyMode,
              onPrivacyModeToggle: () => setState(() => _privacyMode = !_privacyMode),
            ),
            Expanded(
              child: StatisticsDashboardBody(
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
            ),
          ],
        ),
      ),
    );
  }
}
