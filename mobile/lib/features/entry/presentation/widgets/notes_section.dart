import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class NotesSection extends StatelessWidget {
  const NotesSection({super.key, required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final appTextStyles = AppTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('備註', style: appTextStyles.sectionLabel),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: enabled,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '選填',
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
