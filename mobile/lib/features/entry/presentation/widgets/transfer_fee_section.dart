import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart'
    show ThousandsSeparatorInputFormatter;

class TransferFeeSection extends StatelessWidget {
  const TransferFeeSection({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('手續費（選填）', style: theme.textStyles.sectionLabel),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: InputDecoration(
              hintText: '0',
              prefixText: '\$ ',
              prefixStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
