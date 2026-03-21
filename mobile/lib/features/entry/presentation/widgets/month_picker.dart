import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class MonthPicker extends StatelessWidget {
  const MonthPicker({super.key, required this.month, required this.onTap});
  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yearMonth = '${month.year} 年 ${month.month.toString()} 月';
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(yearMonth, style: theme.textStyles.titleEmphasis),
              const SizedBox(width: 2),
              Icon(
                Icons.expand_more_rounded,
                size: 22,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
