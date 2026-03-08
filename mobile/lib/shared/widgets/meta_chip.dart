import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class MetaChip extends StatelessWidget {
  const MetaChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurfaceVariant;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: effectiveIconColor),
              const SizedBox(width: 6),
              Text(label, style: theme.textStyles.body),
              if (trailing != null) ...[const SizedBox(width: 2), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
