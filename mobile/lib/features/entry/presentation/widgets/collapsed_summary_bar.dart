import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class CollapsedSummaryBar extends StatelessWidget {
  static const double height = 44;

  const CollapsedSummaryBar({
    super.key,
    required this.future,
    required this.getSummaryText,
  });

  final Future<dynamic> future;
  final String? Function(dynamic data) getSummaryText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<dynamic>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final text = getSummaryText(snapshot.data);
        if (text == null || text.isEmpty) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Text(
            text,
            style: theme.textStyles.titleEmphasis.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
