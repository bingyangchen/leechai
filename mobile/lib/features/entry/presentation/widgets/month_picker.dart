import 'package:flutter/material.dart';

class MonthPicker extends StatelessWidget {
  const MonthPicker({super.key, required this.month, required this.onTap});
  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final yearMonth = '${month.year} 年 ${month.month.toString().padLeft(2, '0')} 月';
    return TextButton(
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            yearMonth,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface),
        ],
      ),
    );
  }
}
