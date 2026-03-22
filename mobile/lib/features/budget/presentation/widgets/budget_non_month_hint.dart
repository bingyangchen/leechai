import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class BudgetNonMonthHint extends StatelessWidget {
  const BudgetNonMonthHint({super.key, required this.onViewThisMonth});

  final VoidCallback onViewThisMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(child: Text('預算僅支援檢視本月', style: theme.textStyles.body)),
            TextButton(
              onPressed: onViewThisMonth,
              child: Text(
                '查看本月',
                style: theme.textStyles.labelLarge.copyWith(color: cs.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void navigateDateRangeToThisMonth(
  void Function(DateRange range, DateRangePreset? preset) onDateRangeChanged,
) {
  final now = DateTime.now();
  onDateRangeChanged(
    DateRange.forPreset(DateRangePreset.thisMonth, now),
    DateRangePreset.thisMonth,
  );
}
