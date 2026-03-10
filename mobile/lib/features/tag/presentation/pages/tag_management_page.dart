import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/entry/data/repositories/tag.dart' show TagRepository;
import 'package:mobile/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class TagManagementPage extends StatefulWidget {
  const TagManagementPage({super.key, this.refreshTrigger});
  final ValueListenable<int>? refreshTrigger;

  @override
  State<TagManagementPage> createState() => _TagManagementPageState();
}

class _TagManagementPageState extends State<TagManagementPage> {
  Future<List<Map<String, Object?>>>? _tagsFuture;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  void _loadTags() {
    setState(() {
      _tagsFuture = TagRepository.getAllOrderByCreatedAt();
    });
  }

  void _onTagChanged() {
    if (!mounted) return;
    _loadTags();
    (widget.refreshTrigger as ValueNotifier<int>?)?.value++;
  }

  Future<void> _onAddTag() async {
    final updated = await showTagFormSheet(context, onRestore: _onTagChanged);
    if (updated == true && mounted) _onTagChanged();
  }

  Future<void> _onTapTag(Map<String, Object?> tag) async {
    final id = tag['id'] as String?;
    final title = tag['title'] as String?;
    if (id == null || title == null) return;
    final updated = await showTagFormSheet(
      context,
      existingTag: {'id': id, 'title': title},
      onRestore: _onTagChanged,
    );
    if (updated == true && mounted) _onTagChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('標籤管理'),
        toolbarHeight: kToolbarHeight,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(icon: const Icon(Icons.add), onPressed: _onAddTag),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _tagsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(child: Text('尚無標籤', style: theme.textStyles.bodyLargeMuted));
          }
          return _TagList(tags: list, onTap: _onTapTag);
        },
      ),
    );
  }
}

class _TagList extends StatelessWidget {
  const _TagList({required this.tags, required this.onTap});

  final List<Map<String, Object?>> tags;
  final ValueChanged<Map<String, Object?>> onTap;

  static const double _iconSize = 40;
  static const double _iconRadius = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, int>>(
      future: TagRepository.getUsageCountsForTagIds(
        tags.map((t) => t['id'] as String).toList(),
      ),
      builder: (context, countSnapshot) {
        final usageCounts = countSnapshot.data ?? {};

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: tags.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final tag = tags[index];
            final id = tag['id'] as String?;
            final title = tag['title'] as String? ?? '';
            final count = id != null ? (usageCounts[id] ?? 0) : 0;

            return Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Container(
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(_iconRadius),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.label_outline,
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                title: Text(title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count 筆紀錄',
                        style: theme.textStyles.labelSmallMuted.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () => onTap(tag),
              ),
            );
          },
        );
      },
    );
  }
}
