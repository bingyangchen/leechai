import 'package:flutter/material.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

const List<String> _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

class DateHeaderContent extends StatelessWidget {
  const DateHeaderContent({
    super.key,
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTextStyles = AppTextStyles.of(context);
    final dateStr =
        '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    final weekday = _weekdays[date.weekday - 1];
    final expenseStr = privacyMode ? '****' : formatAmountForDisplay(dayExpense);
    final incomeStr = privacyMode ? '****' : formatAmountForDisplay(dayIncome);
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text('$dateStr ($weekday)', style: appTextStyles.titleSmallEmphasis),
          const SizedBox(width: 12),
          Text(
            '支出 \$$expenseStr',
            style: appTextStyles.bodySmallMuted.copyWith(
              color: EntryTypeColors.forType(context, EntryType.expense),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '收入 \$$incomeStr',
            style: appTextStyles.bodySmallMuted.copyWith(
              color: EntryTypeColors.forType(context, EntryType.income),
            ),
          ),
        ],
      ),
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
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DateHeaderContent(
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
