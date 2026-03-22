import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/date_time_picker_sheet.dart';

class DateRangePickerResult {
  const DateRangePickerResult({required this.range, this.preset});

  final DateRange range;
  final DateRangePreset? preset;
}

Future<DateRangePickerResult?> showDateRangePickerSheet(
  BuildContext context, {
  required DateRange initialRange,
  DateRangePreset? initialPreset,
}) async {
  return showAppBottomSheet<DateRangePickerResult>(
    context,
    mode: AppBottomSheetMode.scrollable,
    title: '選擇時間區間',
    scrollableBuilder: (ctx, scrollController) {
      return _DateRangePickerContent(
        initialRange: initialRange,
        initialPreset: initialPreset,
        scrollController: scrollController,
      );
    },
  );
}

class _DateRangePickerContent extends StatefulWidget {
  const _DateRangePickerContent({
    required this.initialRange,
    this.initialPreset,
    required this.scrollController,
  });

  final DateRange initialRange;
  final DateRangePreset? initialPreset;
  final ScrollController scrollController;

  @override
  State<_DateRangePickerContent> createState() => _DateRangePickerContentState();
}

class _DateRangePickerContentState extends State<_DateRangePickerContent> {
  late DateRange _range;
  DateRangePreset? _preset;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
    _preset = widget.initialPreset;
  }

  Future<void> _pickStartMonth() async {
    final picked = await showAppBottomSheet<DateTime>(
      context,
      mode: AppBottomSheetMode.static,
      builder: (ctx) => DateTimePickerSheet(
        initial: _range.start,
        monthOnly: true,
        onConfirm: (v, {fromDrag = false}) {
          if (!fromDrag) Navigator.of(ctx).pop(v);
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _preset = DateRangePreset.custom;
        final end = _range.end;
        if (picked.isAfter(end)) {
          _range = DateRange(
            start: DateTime(picked.year, picked.month, 1),
            end: DateTime(picked.year, picked.month + 1, 0, 23, 59, 59, 999),
          );
        } else {
          _range = DateRange(start: DateTime(picked.year, picked.month, 1), end: end);
        }
      });
    }
  }

  Future<void> _pickEndMonth() async {
    final picked = await showAppBottomSheet<DateTime>(
      context,
      mode: AppBottomSheetMode.static,
      builder: (ctx) => DateTimePickerSheet(
        initial: _range.end,
        monthOnly: true,
        onConfirm: (v, {fromDrag = false}) {
          if (!fromDrag) Navigator.of(ctx).pop(v);
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _preset = DateRangePreset.custom;
        final start = _range.start;
        if (picked.isBefore(start)) {
          _range = DateRange(
            start: DateTime(picked.year, picked.month, 1),
            end: DateTime(picked.year, picked.month + 1, 0, 23, 59, 59, 999),
          );
        } else {
          _range = DateRange(
            start: start,
            end: DateTime(picked.year, picked.month + 1, 0, 23, 59, 59, 999),
          );
        }
      });
    }
  }

  void _selectPreset(DateRangePreset preset) {
    setState(() {
      _preset = preset;
      _range = DateRange.forPreset(preset, DateTime.now());
    });
  }

  void _confirm() {
    Navigator.of(context).pop(DateRangePickerResult(range: _range, preset: _preset));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outlineGhost = theme.colorScheme.outline.withValues(alpha: 0.22);
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in DateRangePreset.values)
                  if (p != DateRangePreset.custom)
                    FilterChip(
                      showCheckmark: false,
                      label: Text(p.label),
                      labelStyle: _preset == p
                          ? theme.textStyles.titleSmallEmphasis.copyWith(
                              color: theme.colorScheme.onPrimary,
                            )
                          : theme.textStyles.sectionLabel.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.85,
                              ),
                              fontWeight: FontWeight.w400,
                            ),
                      selected: _preset == p,
                      onSelected: (selectedValue) {
                        if (selectedValue) {
                          _selectPreset(p);
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
              ],
            ),
            const SizedBox(height: 24),
            Text('自訂區間', style: theme.textStyles.sectionLabel),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStartMonth,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      '${_range.start.year}/${_range.start.month.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('～'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEndMonth,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      '${_range.end.year}/${_range.end.month.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _confirm, child: const Text('確定')),
          ],
        ),
      ),
    );
  }
}
