import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/budget/data/services/budget.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class BudgetProgressCard extends StatefulWidget {
  const BudgetProgressCard({
    super.key,
    required this.privacyMode,
    this.refreshTrigger,
    required this.onOpenSettings,
    this.rankingAnimationTrigger = 0,
    this.showTitleRow = true,
  });

  final bool privacyMode;
  final ValueListenable<int>? refreshTrigger;
  final VoidCallback onOpenSettings;
  final int rankingAnimationTrigger;
  final bool showTitleRow;

  @override
  State<BudgetProgressCard> createState() => _BudgetProgressCardState();
}

class _BudgetProgressCardState extends State<BudgetProgressCard> {
  late Future<MonthBudgetSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    widget.refreshTrigger?.addListener(_onRefresh);
  }

  @override
  void didUpdateWidget(BudgetProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefresh);
      widget.refreshTrigger?.addListener(_onRefresh);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<MonthBudgetSnapshot> _load() async {
    final now = DateTime.now();
    return BudgetService.loadSnapshotForMonth(now.year, now.month, now);
  }

  Color _barFillColor(ColorScheme cs, double ratio) {
    if (ratio >= 1.0) return cs.error;
    if (ratio >= 0.8) return cs.secondary;
    return cs.primary;
  }

  Color _statusDotColor(ColorScheme cs, double ratio, {required bool hasBudget}) {
    if (!hasBudget) {
      return cs.outline.withValues(alpha: 0.35);
    }
    return _barFillColor(cs, ratio).withValues(alpha: 0.72);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<MonthBudgetSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('無法載入預算', style: theme.textStyles.bodyMuted),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const SizedBox.shrink();
        }

        final budget = data.totalBudget;
        final ratio = data.spentRatio;
        final fillColor = budget != null && budget > 0
            ? _barFillColor(cs, ratio)
            : cs.outline.withValues(alpha: 0.35);

        final hasBudget = budget != null && budget > 0;
        return Material(
          color: cs.surfaceContainerHighest,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onOpenSettings,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: hasBudget
                      ? _FilledBudgetBody(
                          key: ValueKey(widget.rankingAnimationTrigger),
                          theme: theme,
                          data: data,
                          privacyMode: widget.privacyMode,
                          fillColor: fillColor,
                          onDetail: widget.onOpenSettings,
                          showTitleRow: widget.showTitleRow,
                        )
                      : _EmptyBudgetBody(
                          theme: theme,
                          onPrimaryAction: widget.onOpenSettings,
                          showTitleRow: widget.showTitleRow,
                        ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: IgnorePointer(
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _statusDotColor(cs, ratio, hasBudget: hasBudget),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyBudgetBody extends StatelessWidget {
  const _EmptyBudgetBody({
    required this.theme,
    required this.onPrimaryAction,
    required this.showTitleRow,
  });

  final ThemeData theme;
  final VoidCallback onPrimaryAction;
  final bool showTitleRow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitleRow) Text('本月預算', style: theme.textStyles.sectionLabel),
        if (showTitleRow) const SizedBox(height: 4),
        Text('尚未設定本月預算', style: theme.textStyles.bodyMuted),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(onPressed: onPrimaryAction, child: const Text('設定預算')),
        ),
      ],
    );
  }
}

class _FilledBudgetBody extends StatefulWidget {
  const _FilledBudgetBody({
    super.key,
    required this.theme,
    required this.data,
    required this.privacyMode,
    required this.fillColor,
    required this.onDetail,
    required this.showTitleRow,
  });

  final ThemeData theme;
  final MonthBudgetSnapshot data;
  final bool privacyMode;
  final Color fillColor;
  final VoidCallback onDetail;
  final bool showTitleRow;

  @override
  State<_FilledBudgetBody> createState() => _FilledBudgetBodyState();
}

class _FilledBudgetBodyState extends State<_FilledBudgetBody> {
  double _previousBarRatio = 0;

  static double _clampedBarRatio(MonthBudgetSnapshot data) {
    return data.spentRatio.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(covariant _FilledBudgetBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_clampedBarRatio(oldWidget.data) != _clampedBarRatio(widget.data)) {
      _previousBarRatio = _clampedBarRatio(oldWidget.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final data = widget.data;
    final privacyMode = widget.privacyMode;
    final fillColor = widget.fillColor;
    final onDetail = widget.onDetail;
    final cs = theme.colorScheme;
    final barRatio = _clampedBarRatio(data);
    final cap = data.totalBudget!;
    final spent = data.spentExpense;
    final remaining = cap - spent;
    final remainingLabel = remaining >= 0 ? '剩餘可用' : '超支';
    final remainingStr = privacyMode
        ? '****'
        : '\$${formatAmountForDisplay(remaining.abs())}';
    final capStr = privacyMode ? '****' : formatAmountForDisplay(cap);
    final daysStr = '${data.remainingDaysInMonth} 天';
    final dailySuggestedRaw = data.dailySuggested ?? 0;
    final dailySuggestedDisplay = dailySuggestedRaw < 0 ? 0.0 : dailySuggestedRaw;
    final dailyStr = data.remainingDaysInMonth <= 0
        ? '—'
        : (privacyMode ? '****' : '\$${formatAmountForDisplay(dailySuggestedDisplay)}');

    final remainingStyle = remaining < 0
        ? theme.textStyles.titleEmphasis.copyWith(color: cs.error)
        : theme.textStyles.titleEmphasis;

    final detailButtonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final detailButtonChild = Text(
      '設定',
      style: theme.textStyles.labelLarge.copyWith(color: cs.primary),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitleRow) ...[
          Row(
            children: [
              Expanded(child: Text('本月預算', style: theme.textStyles.sectionLabel)),
              TextButton(
                style: detailButtonStyle,
                onPressed: onDetail,
                child: detailButtonChild,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            privacyMode ? '預算上限 ****' : '預算上限 \$$capStr',
            style: theme.textStyles.labelSmallMuted,
          ),
          const SizedBox(height: 8),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  privacyMode ? '預算上限 ****' : '預算上限 \$$capStr',
                  style: theme.textStyles.labelSmallMuted,
                ),
              ),
              TextButton(
                style: detailButtonStyle,
                onPressed: onDetail,
                child: detailButtonChild,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TweenAnimationBuilder<double>(
          key: ValueKey(barRatio),
          tween: Tween(begin: _previousBarRatio, end: barRatio),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, animatedRatio, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 9,
                    width: double.infinity,
                    color: cs.outline.withValues(alpha: 0.12),
                  ),
                  FractionallySizedBox(
                    widthFactor: animatedRatio,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 9,
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricColumn(
                label: remainingLabel,
                value: remainingStr,
                valueStyle: remainingStyle,
              ),
            ),
            Expanded(
              child: _MetricColumn(
                label: '本月剩餘天數',
                value: daysStr,
                valueStyle: theme.textStyles.titleEmphasis,
              ),
            ),
            Expanded(
              child: _MetricColumn(
                label: data.remainingDaysInMonth <= 0 ? '今日結算' : '每日建議',
                value: dailyStr,
                valueStyle: theme.textStyles.titleEmphasis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textStyles.bodySmallMuted),
        const SizedBox(height: 2),
        Text(value, style: valueStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
