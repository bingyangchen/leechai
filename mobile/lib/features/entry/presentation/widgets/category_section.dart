import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<({String name, IconData? icon})> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('類別', style: theme.textStyles.sectionLabel),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final selected = index == selectedIndex;
                final icon = cat.icon ?? Icons.more_horiz;
                final backgroundColor = selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.22)
                    : theme.colorScheme.surfaceContainerHighest;
                final contentColor = selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant;
                return Material(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onSelected(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 24, color: contentColor),
                          const SizedBox(height: 2),
                          Text(
                            cat.name,
                            style: theme.textStyles.bodySmallMuted.copyWith(
                              color: contentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
