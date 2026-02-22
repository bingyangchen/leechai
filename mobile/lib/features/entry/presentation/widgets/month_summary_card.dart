import 'package:flutter/material.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
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
    final theme = Theme.of(context);
    final incomeStr = privacyMode ? '****' : formatAmountForDisplay(income);
    final expenseStr = privacyMode ? '****' : formatAmountForDisplay(expense);
    final balanceStr = privacyMode ? '****' : _formatBalance(balance);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '本月結餘',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                balanceStr,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '本月支出',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expenseStr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: EntryTypeColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '本月收入',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        incomeStr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: EntryTypeColors.income,
                          fontWeight: FontWeight.w600,
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
