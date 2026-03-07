import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class MonthPicker extends StatelessWidget {
  const MonthPicker({super.key, required this.month, required this.onTap});
  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTextStyles = AppTextStyles.of(context);
    final yearMonth = '${month.year} 年 ${month.month.toString()} 月';
    return TextButton(
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(yearMonth, style: appTextStyles.titleEmphasis),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
        ],
      ),
    );
  }
}
