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
    this.backgroundColor,
    this.truncateLabel = false,
  });

  static const double horizontalPadding = 12;
  static const double verticalPadding = 8;
  static const double leadingIconSize = 18;
  static const double labelSpacing = 6;
  static const double trailingSpacing = 2;

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  final Color? iconColor;
  final Widget? trailing;
  final Color? backgroundColor;
  final bool truncateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurfaceVariant;

    return Material(
      color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: leadingIconSize, color: effectiveIconColor),
              const SizedBox(width: labelSpacing),
              if (truncateLabel)
                Flexible(
                  child: Text(
                    label,
                    style: theme.textStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Text(label, style: theme.textStyles.body),
              if (trailing != null) ...[
                const SizedBox(width: trailingSpacing),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
