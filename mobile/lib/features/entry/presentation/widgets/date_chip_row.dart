import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
            label: DateFormat(
              selectedDate.year != DateTime.now().year
                  ? 'y/MM/dd hh:mm a'
                  : 'MM/dd hh:mm a',
            ).format(selectedDate),
            onTap: onDateTap,
          ),
        ],
      ),
    );
  }
}
