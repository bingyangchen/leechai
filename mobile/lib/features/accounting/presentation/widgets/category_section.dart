import 'package:flutter/material.dart';
import 'package:mobile/features/accounting/domain/constants/expense_category.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.selectedMainIndex,
    this.selectedSubIndex,
    required this.onMainSelected,
    required this.onSubSelected,
  });

  final int selectedMainIndex;
  final int? selectedSubIndex;
  final ValueChanged<int> onMainSelected;
  final ValueChanged<int?> onSubSelected;

  @override
  Widget build(BuildContext context) {
    final subs =
        expenseSubCategories[selectedMainIndex] ?? expenseSubCategories[5]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '類別',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: expenseMainCategories.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = expenseMainCategories[index];
                final selected = index == selectedMainIndex;
                return Material(
                  color: selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onMainSelected(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat.icon,
                            size: 24,
                            color: selected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 3;
              const spacing = 8.0;
              final width =
                  (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                  crossAxisCount;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(subs.length, (index) {
                  final selected = selectedSubIndex == index;
                  return SizedBox(
                    width: width,
                    child: Material(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => onSubSelected(selected ? null : index),
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              subs[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: selected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
