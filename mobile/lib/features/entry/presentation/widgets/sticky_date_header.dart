import 'package:flutter/material.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

const List<String> _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

Widget dateHeaderContent({
  required DateTime date,
  required double dayExpense,
  required double dayIncome,
  required bool privacyMode,
  required BuildContext context,
}) {
  final theme = Theme.of(context);
  final dateStr =
      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  final weekday = _weekdays[date.weekday - 1];
  final expenseStr = privacyMode ? '****' : formatAmountForDisplay(dayExpense);
  final incomeStr = privacyMode ? '****' : formatAmountForDisplay(dayIncome);
  return Container(
    color: theme.colorScheme.surface,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    alignment: Alignment.centerLeft,
    child: Row(
      children: [
        Text(
          '$dateStr ($weekday)',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 12),
        Text(
          '支出 \$$expenseStr',
          style: theme.textTheme.bodySmall?.copyWith(
            color: EntryTypeColors.forType(context, EntryType.expense),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '收入 \$$incomeStr',
          style: theme.textTheme.bodySmall?.copyWith(
            color: EntryTypeColors.forType(context, EntryType.income),
          ),
        ),
      ],
    ),
  );
}

/// In-list date header (scrolls with content). Use with a GlobalKey to track position.
Widget buildDateHeaderSection({
  required DateTime date,
  required double dayExpense,
  required double dayIncome,
  required bool privacyMode,
  required BuildContext context,
  Key? key,
}) {
  return KeyedSubtree(
    key: key,
    child: dateHeaderContent(
      context: context,
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
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return dateHeaderContent(
      context: context,
      date: date,
      dayExpense: dayExpense,
      dayIncome: dayIncome,
      privacyMode: privacyMode,
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
