import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/features/statistics/domain/net_worth_range.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class StatisticsTopBar extends StatelessWidget {
  const StatisticsTopBar({
    super.key,
    required this.tabIndex,
    required this.dateRange,
    required this.preset,
    required this.onDateRangeTap,
    required this.netWorthRange,
    required this.onNetWorthRangeSelected,
    required this.privacyMode,
    required this.onPrivacyModeToggle,
  });

  final int tabIndex;
  final DateRange dateRange;
  final DateRangePreset? preset;
  final Future<void> Function() onDateRangeTap;
  final NetWorthRange netWorthRange;
  final ValueChanged<NetWorthRange> onNetWorthRangeSelected;
  final bool privacyMode;
  final VoidCallback onPrivacyModeToggle;

  Widget _timeSelector(BuildContext context) {
    final theme = Theme.of(context);
    if (tabIndex == 0) {
      return Align(
        key: const ValueKey('date_btn'),
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
      );
    }
    return Align(
      key: const ValueKey('chips'),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: NetWorthRange.values.map((range) {
            final selected = range == netWorthRange;
            final outlineGhost = theme.colorScheme.outline.withValues(alpha: 0.22);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                showCheckmark: false,
                label: Text(range.label),
                labelStyle: selected
                    ? theme.textStyles.titleSmallEmphasis.copyWith(
                        color: theme.colorScheme.onPrimary,
                      )
                    : theme.textStyles.sectionLabel.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.85,
                        ),
                        fontWeight: FontWeight.w400,
                      ),
                selected: selected,
                onSelected: (selectedValue) {
                  if (selectedValue) {
                    onNetWorthRangeSelected(range);
                  }
                },
                color: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.colorScheme.primary;
                  }
                  return theme.colorScheme.surface.withValues(alpha: 0);
                }),
                side: WidgetStateBorderSide.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return BorderSide(color: theme.colorScheme.primary);
                  }
                  return BorderSide(color: outlineGhost);
                }),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
                child: _timeSelector(context),
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
