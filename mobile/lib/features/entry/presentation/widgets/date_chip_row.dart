import 'package:flutter/material.dart';
import 'package:mobile/shared/utils/date_time_utils.dart';
import 'package:mobile/shared/widgets/meta_chip.dart';

class DateChipRow extends StatelessWidget {
  const DateChipRow({super.key, required this.selectedDate, required this.onDateTap});

  final DateTime selectedDate;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          MetaChip(
            icon: Icons.calendar_today_outlined,
            label: formatDateTime(selectedDate),
            onTap: onDateTap,
          ),
        ],
      ),
    );
  }
}
