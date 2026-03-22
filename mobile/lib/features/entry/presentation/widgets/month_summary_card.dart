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
    final theme = Theme.of(context);
    final incomeStr = privacyMode ? '****' : formatAmountForDisplay(income);
    final expenseStr = privacyMode ? '****' : formatAmountForDisplay(expense);
    final balanceStr = privacyMode ? '****' : _formatBalance(balance);
    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('本月結餘', style: theme.textStyles.sectionLabel),
              const SizedBox(height: 4),
              Text(balanceStr, style: theme.textStyles.headlineEmphasis),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('本月支出', style: theme.textStyles.bodySmallMuted),
                        const SizedBox(height: 2),
                        Text(
                          expenseStr,
                          style: theme.textStyles.titleEmphasis.copyWith(
                            color: EntryTypeColors.forType(context, EntryType.expense),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 2,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: dividerColor,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('本月收入', style: theme.textStyles.bodySmallMuted),
                        const SizedBox(height: 2),
                        Text(
                          incomeStr,
                          style: theme.textStyles.titleEmphasis.copyWith(
                            color: EntryTypeColors.forType(context, EntryType.income),
                          ),
                        ),
                      ],
                    ),
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
