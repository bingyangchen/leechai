import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class StatisticsTopBar extends StatelessWidget {
  const StatisticsTopBar({
    super.key,
    required this.dateRange,
    required this.preset,
    required this.onDateRangeTap,
    required this.privacyMode,
    required this.onPrivacyModeToggle,
  });

  final DateRange dateRange;
  final DateRangePreset? preset;
  final Future<void> Function() onDateRangeTap;
  final bool privacyMode;
  final VoidCallback onPrivacyModeToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: AppTheme.topBarControlSlotHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onDateRangeTap(),
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
                          Text(
                            dateRange.toShortLabel(preset),
                            style: theme.textStyles.titleEmphasis,
                          ),
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
                ),
              ),
            ),
          ),
          IconButton(
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              fixedSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              privacyMode ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: privacyMode
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: onPrivacyModeToggle,
            tooltip: privacyMode ? '關閉隱私模式' : '隱私模式',
          ),
        ],
      ),
    );
  }
}
