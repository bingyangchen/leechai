import 'package:flutter/material.dart';

class CollapsedSummaryBar extends StatelessWidget {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
