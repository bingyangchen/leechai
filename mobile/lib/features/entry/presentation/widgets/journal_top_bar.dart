import 'package:flutter/material.dart';
import 'package:mobile/features/entry/presentation/widgets/month_picker.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/date_time_picker_sheet.dart';

class JournalTopBar extends StatelessWidget {
  const JournalTopBar({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.privacyMode,
    required this.onPrivacyModeToggle,
  });

  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;
  final bool privacyMode;
  final VoidCallback onPrivacyModeToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          MonthPicker(
            month: selectedMonth,
            onTap: () async {
              final picked = await showAppBottomSheet<DateTime>(
                context,
                mode: AppBottomSheetMode.static,
                builder: (ctx) => DateTimePickerSheet(
                  initial: selectedMonth,
                  monthOnly: true,
                  onConfirm: (v, {fromDrag = false}) {
                    if (fromDrag) onMonthSelected(v);
                    if (!fromDrag) Navigator.of(ctx).pop(v);
                  },
                  onCancel: () => Navigator.of(ctx).pop(),
                ),
              );
              if (picked != null) onMonthSelected(picked);
            },
          ),
          const Spacer(),
          IconButton(
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              fixedSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              privacyMode ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: onPrivacyModeToggle,
            tooltip: privacyMode ? '關閉隱私模式' : '隱私模式',
          ),
        ],
      ),
    );
  }
}
