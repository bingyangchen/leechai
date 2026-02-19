import 'package:flutter/material.dart';

class TagsSection extends StatelessWidget {
  const TagsSection({
    super.key,
    required this.tags,
    required this.inputController,
    required this.enabled,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final List<String> tags;
  final TextEditingController inputController;
  final bool enabled;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '標籤',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final tag in tags)
                        Chip(
                          label: Text(tag),
                          deleteIcon: Icon(
                            Icons.close,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onDeleted: enabled ? () => onRemoveTag(tag) : null,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: inputController,
                        enabled: enabled,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '新增標籤或專案，按 Enter 或 ＋ 加入',
                        ),
                        onSubmitted: (value) => onAddTag(value),
                      ),
                    ),
                    IconButton(
                      onPressed: enabled
                          ? () => onAddTag(inputController.text)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
