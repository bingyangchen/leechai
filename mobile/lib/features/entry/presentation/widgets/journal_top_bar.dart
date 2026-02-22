import 'package:flutter/material.dart';
import 'package:mobile/features/entry/presentation/widgets/month_picker.dart';
import 'package:mobile/features/entry/presentation/widgets/sync_indicator.dart';
import 'package:mobile/shared/widgets/date_time_picker_sheet.dart';

class JournalTopBar extends StatelessWidget {
  const JournalTopBar({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.syncStatus,
    required this.privacyMode,
    required this.onPrivacyModeToggle,
  });

  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;
  final SyncStatus syncStatus;
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
              final picked = await showModalBottomSheet<DateTime>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
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
          SyncIndicator(status: syncStatus),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              privacyMode ? Icons.visibility_off : Icons.visibility,
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
