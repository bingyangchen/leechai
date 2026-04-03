import 'package:flutter/material.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
import 'package:mobile/features/entry/presentation/constants/journal_sticky_strip.dart';
import 'package:mobile/shared/constants/weekday.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

const double kDateHeaderBarExtent = journalStickyStripRowHeight;

class DateHeaderContent extends StatelessWidget {
  const DateHeaderContent({
    super.key,
    required this.date,
    required this.dayExpense,
    required this.dayIncome,
    required this.privacyMode,
    this.pinned = false,
  });

  final DateTime date;
  final double dayExpense;
  final double dayIncome;
  final bool privacyMode;

  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    final weekday = chineseWeekdayLabels[date.weekday - 1];
    final expenseStr = privacyMode ? '****' : formatAmountForDisplay(dayExpense);
    final incomeStr = privacyMode ? '****' : formatAmountForDisplay(dayIncome);
    final outlineAlpha = pinned ? 0.14 : 0.12;
    final bottomLineColor = theme.colorScheme.outline.withValues(alpha: outlineAlpha);
    final expenseColor = EntryTypeColors.forType(context, EntryType.expense);
    final incomeColor = EntryTypeColors.forType(context, EntryType.income);

    final separatorColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35);

    return SizedBox(
      height: journalStickyStripRowHeight,
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '$dateStr ($weekday)',
                        style: theme.textStyles.sectionLabel.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _InlineDayAmount(
                                label: '支出',
                                amount: expenseStr,
                                amountColor: expenseColor,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 7),
                                child: Text(
                                  '·',
                                  style: theme.textTheme.bodySmall!.copyWith(
                                    color: separatorColor,
                                    height: 1,
                                  ),
                                ),
                              ),
                              _InlineDayAmount(
                                label: '收入',
                                amount: incomeStr,
                                amountColor: incomeColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 1, child: ColoredBox(color: bottomLineColor)),
          ],
        ),
      ),
    );
  }
}

class _InlineDayAmount extends StatelessWidget {
  const _InlineDayAmount({
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  final String label;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textStyles.bodySmallMuted),
        const SizedBox(width: 4),
        Text(
          '\$$amount',
          style: theme.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: amountColor,
            height: 1.2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

Widget buildDateHeaderSection({
  required DateTime date,
  required double dayExpense,
  required double dayIncome,
  required bool privacyMode,
  Key? key,
}) {
  return KeyedSubtree(
    key: key,
    child: DateHeaderContent(
      date: date,
      dayExpense: dayExpense,
      dayIncome: dayIncome,
      privacyMode: privacyMode,
    ),
  );
}

SliverPersistentHeader stickyDateHeader({
  required DateTime date,
  required double dayExpense,
  required double dayIncome,
  required bool privacyMode,
}) {
  return SliverPersistentHeader(
    pinned: true,
    delegate: _StickyDateDelegate(
      date: date,
      dayExpense: dayExpense,
      dayIncome: dayIncome,
      privacyMode: privacyMode,
    ),
  );
}

class _StickyDateDelegate extends SliverPersistentHeaderDelegate {
  _StickyDateDelegate({
    required this.date,
    required this.dayExpense,
    required this.dayIncome,
    required this.privacyMode,
  });

  final DateTime date;
  final double dayExpense;
  final double dayIncome;
  final bool privacyMode;

  @override
  double get minExtent => kDateHeaderBarExtent;

  @override
  double get maxExtent => kDateHeaderBarExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DateHeaderContent(
      date: date,
      dayExpense: dayExpense,
      dayIncome: dayIncome,
      privacyMode: privacyMode,
      pinned: true,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyDateDelegate old) {
    return old.date != date ||
        old.dayExpense != dayExpense ||
        old.dayIncome != dayIncome ||
        old.privacyMode != privacyMode;
  }
}
