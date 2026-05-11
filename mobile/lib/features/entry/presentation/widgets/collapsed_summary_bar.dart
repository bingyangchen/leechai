import 'package:flutter/material.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
import 'package:mobile/features/entry/presentation/constants/journal_sticky_strip.dart';
import 'package:mobile/shared/theme/app_theme.dart';

enum CollapsedSummaryTone { neutral, income, expense }

class CollapsedSummaryBarData {
  const CollapsedSummaryBarData({
    required this.title,
    required this.amount,
    required this.tone,
  });

  final String title;
  final String amount;
  final CollapsedSummaryTone tone;
}

class CollapsedSummaryBar extends StatelessWidget {
  static const double height = journalStickyStripRowHeight;

  const CollapsedSummaryBar({
    super.key,
    required this.future,
    required this.getSummary,
  });

  final Future<dynamic> future;
  final CollapsedSummaryBarData? Function(dynamic data) getSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return FutureBuilder<dynamic>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final summary = getSummary(snapshot.data);
        if (summary == null) return const SizedBox.shrink();
        final accentColor = switch (summary.tone) {
          CollapsedSummaryTone.income => EntryTypeColors.forType(
            context,
            EntryType.income,
          ),
          CollapsedSummaryTone.expense => EntryTypeColors.forType(
            context,
            EntryType.expense,
          ),
          CollapsedSummaryTone.neutral => colorScheme.onSurfaceVariant.withValues(
            alpha: 0.35,
          ),
        };
        return Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 3,
                height: 20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  summary.title,
                  style: theme.textStyles.sectionLabel.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      summary.amount,
                      maxLines: 1,
                      style: theme.textStyles.titleEmphasis.copyWith(
                        color: colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
