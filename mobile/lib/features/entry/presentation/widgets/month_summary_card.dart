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
    required this.hasEntries,
    required this.privacyMode,
  });

  final double income;
  final double expense;
  final double balance;
  final bool hasEntries;
  final bool privacyMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final incomeColor = EntryTypeColors.forType(context, EntryType.income);
    final expenseColor = EntryTypeColors.forType(context, EntryType.expense);
    final hideAmounts = privacyMode && hasEntries;
    final incomeStr = hideAmounts ? '****' : formatAmountForDisplay(income);
    final expenseStr = hideAmounts ? '****' : formatAmountForDisplay(expense);
    final balanceStr = hideAmounts ? '****' : formatMonthSummaryBalance(balance);
    final balanceTitle = monthSummaryTitle(
      balance: balance,
      hasEntries: hasEntries,
      privacyMode: privacyMode,
    );
    final balanceColor = privacyMode || !hasEntries
        ? colorScheme.onSurface
        : balance > 0
        ? incomeColor
        : balance < 0
        ? expenseColor
        : colorScheme.onSurface;
    final dividerColor = colorScheme.outline.withValues(alpha: 0.12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(balanceTitle, style: theme.textStyles.sectionLabel),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          balanceStr,
                          maxLines: 1,
                          style: theme.textStyles.headlineEmphasis.copyWith(
                            color: balanceColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              SizedBox(
                height: 58,
                child: VerticalDivider(width: 1, thickness: 1, color: dividerColor),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SummaryAmountRow(
                      label: '收入',
                      amount: incomeStr,
                      accentColor: incomeColor,
                    ),
                    const SizedBox(height: 10),
                    _SummaryAmountRow(
                      label: '支出',
                      amount: expenseStr,
                      accentColor: expenseColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryAmountRow extends StatelessWidget {
  const _SummaryAmountRow({
    required this.label,
    required this.amount,
    required this.accentColor,
  });

  final String label;
  final String amount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        SizedBox.square(
          dimension: 7,
          child: DecoratedBox(
            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textStyles.bodySmallMuted,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                amount,
                maxLines: 1,
                style: theme.textStyles.titleEmphasis.copyWith(
                  color: colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String monthSummaryTitle({
  required double balance,
  required bool hasEntries,
  required bool privacyMode,
}) {
  if (!hasEntries) return '本月尚無紀錄';
  if (privacyMode) return '本月收支差額';
  if (balance > 0) return '本月淨流入';
  if (balance < 0) return '本月淨流出';
  return '本月收支打平';
}

String formatMonthSummaryBalance(double value) {
  if (value == 0) return formatAmountForDisplay(0);
  if (value > 0) return '+${formatAmountForDisplay(value)}';
  return '-${formatAmountForDisplay(-value)}';
}
