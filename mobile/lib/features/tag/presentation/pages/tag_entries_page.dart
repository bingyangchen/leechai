import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/data/repositories/tag.dart' show TagRepository;
import 'package:mobile/features/entry/domain/entry_aggregation.dart';
import 'package:mobile/features/entry/presentation/entry_list_handlers.dart';
import 'package:mobile/features/entry/presentation/widgets/entry_row.dart';
import 'package:mobile/features/entry/presentation/widgets/sticky_date_header.dart'
    show buildDateHeaderSection;
import 'package:mobile/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:mobile/shared/scopes/data_refresh.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/refresh_snap_back.dart';
import 'package:mobile/shared/utils/snackbar.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/app_refresh_indicator.dart';
import 'package:mobile/shared/widgets/confirm_delete_dialog.dart';
import 'package:mobile/shared/widgets/haptic_refresh_wrapper.dart';

class TagEntriesPage extends StatefulWidget {
  const TagEntriesPage({
    super.key,
    required this.tagId,
    required this.initialTitle,
    this.refreshTrigger,
  });

  final String tagId;
  final String initialTitle;
  final ValueListenable<int>? refreshTrigger;

  @override
  State<TagEntriesPage> createState() => _TagEntriesPageState();
}

class _TagEntriesPageState extends State<TagEntriesPage> {
  static const int _entryBatchSize = 30;
  static const double _loadMoreExtentAfterThresholdPx = 640;

  late Future<_TagEntriesData> _future;
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, Object?>> _entries = [];
  final Map<String, List<String>> _entryIdToTagTitles = {};
  bool _hasMoreEntries = true;
  bool _isLoadingMoreEntries = false;
  Object? _loadMoreError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMoreEntries);
    _future = _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<_TagEntriesData> _loadData() async {
    _entries.clear();
    _entryIdToTagTitles.clear();
    _hasMoreEntries = true;
    _isLoadingMoreEntries = false;
    _loadMoreError = null;

    final tag = await TagRepository.getById(widget.tagId);
    if (tag == null) throw StateError('Tag not found: ${widget.tagId}');
    final accounts = <String, Account>{};
    for (final account in await AccountRepository.getAll()) {
      accounts[account.id] = account;
    }
    final usageCount = await TagRepository.getUsageCount(widget.tagId);
    final firstBatch = await _loadEntryBatch(offset: 0);
    _entries.addAll(firstBatch.entries);
    _entryIdToTagTitles.addAll(firstBatch.entryIdToTagTitles);
    _hasMoreEntries = firstBatch.entries.length == _entryBatchSize;

    return _TagEntriesData(
      title: tag['title'] as String? ?? widget.initialTitle,
      accounts: accounts,
      usageCount: usageCount,
    );
  }

  Future<_EntryBatchData> _loadEntryBatch({required int offset}) async {
    final entries = await EntryRepository.getByTagIdBatch(
      widget.tagId,
      limit: _entryBatchSize,
      offset: offset,
    );
    final entryIds = entries.map((entry) => entry['id'] as String).toList();
    final entryIdToTagTitles = await EntryRepository.getTagTitlesForEntries(entryIds);
    return _EntryBatchData(entries: entries, entryIdToTagTitles: entryIdToTagTitles);
  }

  void _maybeLoadMoreEntries() {
    if (!_scrollController.hasClients ||
        !_hasMoreEntries ||
        _isLoadingMoreEntries ||
        _loadMoreError != null) {
      return;
    }
    if (_scrollController.position.extentAfter > _loadMoreExtentAfterThresholdPx) {
      return;
    }
    _loadMoreEntries();
  }

  Future<void> _loadMoreEntries() async {
    if (_isLoadingMoreEntries || !_hasMoreEntries) return;
    setState(() {
      _isLoadingMoreEntries = true;
      _loadMoreError = null;
    });
    try {
      final batch = await _loadEntryBatch(offset: _entries.length);
      if (!mounted) return;
      setState(() {
        _entries.addAll(batch.entries);
        _entryIdToTagTitles.addAll(batch.entryIdToTagTitles);
        _hasMoreEntries = batch.entries.length == _entryBatchSize;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadMoreError = error);
    } finally {
      if (mounted) {
        setState(() => _isLoadingMoreEntries = false);
      }
    }
  }

  void _onRefresh() {
    setState(() {
      _future = _loadData();
    });
  }

  void _notifyTagChanged() {
    final refreshTrigger = widget.refreshTrigger;
    if (refreshTrigger is ValueNotifier<int>) {
      refreshTrigger.value++;
    }
    if (mounted) DataRefreshScope.notify(context);
  }

  Future<void> _onOpenSettings(_TagEntriesData data) async {
    final theme = Theme.of(context);
    await showAppBottomSheet<void>(
      context,
      mode: AppBottomSheetMode.static,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('編輯標籤'),
            onTap: () {
              Navigator.pop(sheetContext);
              _onEditTag(data);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text(
              '刪除標籤',
              style: theme.textStyles.bodyLargeMuted.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              _onDeleteTag(data);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onEditTag(_TagEntriesData data) async {
    final updated = await showTagFormSheet(
      context,
      existingTag: {'id': widget.tagId, 'title': data.title},
    );
    if (updated != true || !mounted) return;

    final tag = await TagRepository.getById(widget.tagId);
    _notifyTagChanged();
    if (!mounted) return;
    if (tag == null) {
      Navigator.of(context).pop(true);
      return;
    }
    _onRefresh();
  }

  Future<void> _onDeleteTag(_TagEntriesData data) async {
    final content = data.usageCount > 0
        ? '確定要刪除標籤「${data.title}」嗎？\n這將影響 ${data.usageCount} 筆記帳紀錄，且刪除後無法復原。'
        : '確定要刪除標籤「${data.title}」嗎？';
    final confirmed = await ConfirmDeleteDialog.show(context, content: content);
    if (confirmed != true || !mounted) return;

    final tagId = widget.tagId;
    final refreshTrigger = widget.refreshTrigger;
    await TagRepository.softDelete(tagId);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final overlayContext = Navigator.of(context).overlay?.context;
    _notifyTagChanged();
    Navigator.of(context).pop(true);
    showReplacingSnackBarForMessenger(
      messenger,
      SnackBar(
        content: const Text('標籤已刪除'),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: '復原',
          onPressed: () async {
            await TagRepository.restore(tagId);
            if (overlayContext != null && overlayContext.mounted) {
              if (refreshTrigger is ValueNotifier<int>) {
                refreshTrigger.value++;
              }
              DataRefreshScope.notify(overlayContext);
            }
            showReplacingSnackBarForMessenger(
              messenger,
              const SnackBar(
                content: Text('已復原'),
                duration: Duration(milliseconds: 1500),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onPullToRefresh() async {
    await runRefreshWithSnapBack(_scrollController, () async {
      await Future.delayed(const Duration(milliseconds: 600));
      _onRefresh();
      await _future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight,
        title: FutureBuilder<_TagEntriesData>(
          future: _future,
          builder: (context, snapshot) {
            final title = snapshot.data?.title ?? widget.initialTitle;
            return Text('#$title');
          },
        ),
        actions: [
          FutureBuilder<_TagEntriesData>(
            future: _future,
            builder: (context, snapshot) {
              return IconButton(
                onPressed: snapshot.hasData
                    ? () => _onOpenSettings(snapshot.data!)
                    : null,
                icon: const Icon(Icons.settings_outlined),
                tooltip: '標籤設定',
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_TagEntriesData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('無法載入標籤紀錄', style: theme.textStyles.titleMuted));
          }
          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();
          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMoreEntries());

          final grouped = groupEntriesByDate(_entries);
          return HapticRefreshWrapper(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                appSliverRefreshControl(onRefresh: _onPullToRefresh),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      '共 ${data.usageCount} 筆紀錄',
                      style: theme.textStyles.bodySmallMuted,
                    ),
                  ),
                ),
                if (_entries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.label_outline,
                            size: 64,
                            color: theme.colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text('這個標籤還沒有紀錄', style: theme.textStyles.titleMuted),
                        ],
                      ),
                    ),
                  )
                else ...[
                  for (final entryGroup in grouped.entries) ...[
                    SliverToBoxAdapter(
                      child: buildDateHeaderSection(
                        date: entryGroup.key,
                        dayExpense: dayExpense(entryGroup.value),
                        dayIncome: dayIncome(entryGroup.value),
                        privacyMode: false,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entry = entryGroup.value[index];
                        return EntryRow(
                          entry: entry,
                          accounts: data.accounts,
                          entryTagTitles: _entryIdToTagTitles,
                          privacyMode: false,
                          onTap: () =>
                              EntryListHandlers.openEntry(context, entry, _onRefresh),
                          onDelete: () =>
                              EntryListHandlers.deleteEntry(context, entry, _onRefresh),
                          onCopy: () =>
                              EntryListHandlers.copyEntry(context, entry, _onRefresh),
                        );
                      }, childCount: entryGroup.value.length),
                    ),
                  ],
                  if (_isLoadingMoreEntries)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    )
                  else if (_loadMoreError != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: _loadMoreEntries,
                            icon: const Icon(Icons.refresh),
                            label: const Text('載入失敗，重試'),
                          ),
                        ),
                      ),
                    ),
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TagEntriesData {
  const _TagEntriesData({
    required this.title,
    required this.accounts,
    required this.usageCount,
  });

  final String title;
  final Map<String, Account> accounts;
  final int usageCount;
}

class _EntryBatchData {
  const _EntryBatchData({required this.entries, required this.entryIdToTagTitles});

  final List<Map<String, Object?>> entries;
  final Map<String, List<String>> entryIdToTagTitles;
}
