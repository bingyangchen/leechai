import 'package:flutter/material.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    required this.privacyMode,
  });

  final double income;
  final double expense;
  final double balance;
  final bool privacyMode;

  static String _formatBalance(double v) {
    if (v >= 0) return '+${formatAmountForDisplay(v)}';
    return '-${formatAmountForDisplay(-v)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTextStyles = AppTextStyles.of(context);
    final incomeStr = privacyMode ? '****' : formatAmountForDisplay(income);
    final expenseStr = privacyMode ? '****' : formatAmountForDisplay(expense);
    final balanceStr = privacyMode ? '****' : _formatBalance(balance);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('本月結餘', style: appTextStyles.sectionLabel),
              const SizedBox(height: 4),
              Text(balanceStr, style: appTextStyles.headlineEmphasis),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('本月支出', style: appTextStyles.bodySmallMuted),
                      const SizedBox(height: 2),
                      Text(
                        expenseStr,
                        style: appTextStyles.titleEmphasis.copyWith(
                          color: EntryTypeColors.forType(context, EntryType.expense),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('本月收入', style: appTextStyles.bodySmallMuted),
                      const SizedBox(height: 2),
                      Text(
                        incomeStr,
                        style: appTextStyles.titleEmphasis.copyWith(
                          color: EntryTypeColors.forType(context, EntryType.income),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
