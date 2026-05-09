import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/services/journal_search.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/entry_list_handlers.dart';
import 'package:mobile/features/entry/presentation/widgets/entry_row.dart';
import 'package:mobile/shared/constants/weekday.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

const double _journalSearchEmptyIconSize = 40;
const double _journalSearchEmptyIconOpacity = 0.35;

class JournalSearchPage extends StatefulWidget {
  const JournalSearchPage({
    super.key,
    required this.onDataChanged,
    this.refreshTrigger,
  });

  final VoidCallback onDataChanged;
  final ValueListenable<int>? refreshTrigger;

  @override
  State<JournalSearchPage> createState() => _JournalSearchPageState();
}

class _JournalSearchPageState extends State<JournalSearchPage> {
  static const int _searchBatchSize = 30;
  static const double _loadMoreExtentAfterThresholdPx = 640;

  final TextEditingController _queryController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  String _debouncedQuery = '';
  Map<String, Account>? _accounts;
  final List<Map<String, Object?>> _entries = [];
  final Map<String, List<String>> _entryIdToTagTitles = {};
  Object? _loadError;
  Object? _searchError;
  bool _accountsLoadInProgress = false;
  bool _initialSearchInProgress = false;
  bool _loadMoreInProgress = false;
  bool _hasMoreResults = false;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
    _scrollController.addListener(_maybeLoadMoreResults);
    widget.refreshTrigger?.addListener(_onExternalRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
    _loadAccounts();
  }

  @override
  void didUpdateWidget(covariant JournalSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onExternalRefresh);
      widget.refreshTrigger?.addListener(_onExternalRefresh);
    }
  }

  void _onExternalRefresh() {
    _loadAccounts();
    final query = _debouncedQuery.trim();
    if (query.isNotEmpty) {
      _startSearch(query);
    }
  }

  void _onQueryChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final query = _queryController.text.trim();
      setState(() {
        _debouncedQuery = query;
      });
      _startSearch(query);
    });
    setState(() {});
  }

  void _onEntryMutation() {
    widget.onDataChanged();
    final query = _debouncedQuery.trim();
    if (query.isNotEmpty) {
      _startSearch(query);
    }
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _accountsLoadInProgress = true;
      _loadError = null;
    });
    try {
      final loaded = await JournalSearchService.loadAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = loaded;
        _accountsLoadInProgress = false;
        _loadError = null;
      });
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('JournalSearchPage accounts load failed: $error\n$stackTrace');
      }
      if (!mounted) return;
      setState(() {
        _accountsLoadInProgress = false;
        _loadError = error;
      });
    }
  }

  Future<void> _startSearch(String query) async {
    final generation = ++_searchGeneration;
    if (query.trim().isEmpty) {
      setState(() {
        _entries.clear();
        _entryIdToTagTitles.clear();
        _hasMoreResults = false;
        _initialSearchInProgress = false;
        _loadMoreInProgress = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _entries.clear();
      _entryIdToTagTitles.clear();
      _hasMoreResults = true;
      _initialSearchInProgress = true;
      _loadMoreInProgress = false;
      _searchError = null;
    });
    try {
      final batch = await JournalSearchService.search(
        query: query,
        limit: _searchBatchSize,
        offset: 0,
      );
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _entries.addAll(batch.entries);
        _entryIdToTagTitles.addAll(batch.entryIdToTagTitles);
        _hasMoreResults = batch.entries.length == _searchBatchSize;
        _initialSearchInProgress = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMoreResults());
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('JournalSearchPage search failed: $error\n$stackTrace');
      }
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _initialSearchInProgress = false;
        _hasMoreResults = false;
        _searchError = error;
      });
    }
  }

  void _maybeLoadMoreResults() {
    if (!_scrollController.hasClients ||
        !_hasMoreResults ||
        _initialSearchInProgress ||
        _loadMoreInProgress ||
        _searchError != null ||
        _debouncedQuery.trim().isEmpty) {
      return;
    }
    if (_scrollController.position.extentAfter > _loadMoreExtentAfterThresholdPx) {
      return;
    }
    _loadMoreResults();
  }

  Future<void> _loadMoreResults() async {
    if (_loadMoreInProgress || !_hasMoreResults) return;
    final generation = _searchGeneration;
    final query = _debouncedQuery.trim();
    if (query.isEmpty) return;

    setState(() {
      _loadMoreInProgress = true;
      _searchError = null;
    });
    try {
      final batch = await JournalSearchService.search(
        query: query,
        limit: _searchBatchSize,
        offset: _entries.length,
      );
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _entries.addAll(batch.entries);
        _entryIdToTagTitles.addAll(batch.entryIdToTagTitles);
        _hasMoreResults = batch.entries.length == _searchBatchSize;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMoreResults());
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('JournalSearchPage load more failed: $error\n$stackTrace');
      }
      if (!mounted || generation != _searchGeneration) return;
      setState(() => _searchError = error);
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _loadMoreInProgress = false);
      }
    }
  }

  void _clearQuery() {
    _debounceTimer?.cancel();
    _queryController.clear();
    _searchGeneration++;
    setState(() {
      _debouncedQuery = '';
      _entries.clear();
      _entryIdToTagTitles.clear();
      _hasMoreResults = false;
      _initialSearchInProgress = false;
      _loadMoreInProgress = false;
      _searchError = null;
    });
    _searchFocusNode.requestFocus();
  }

  String get _liveQueryTrimmed => _queryController.text.trim();

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onExternalRefresh);
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final queryTrimmed = _queryController.text.trim();
    final showClear = queryTrimmed.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: BackButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop();
          },
        ),
        titleSpacing: 8,
        title: Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    cursorColor: colorScheme.primary,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '搜尋交易紀錄',
                      hintStyle: theme.inputDecorationTheme.hintStyle,
                    ),
                    onSubmitted: (_) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                ),
                if (showClear)
                  IconButton(
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      fixedSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _clearQuery,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    tooltip: '清除',
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loadError != null) {
      return _KeyboardDismissibleViewport(
        child: _SearchErrorBody(onRetry: _loadAccounts),
      );
    }
    if (_accountsLoadInProgress && _accounts == null) {
      return _KeyboardDismissibleViewport(
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }
    final accounts = _accounts;
    if (accounts == null) {
      return const SizedBox.shrink();
    }

    if (_liveQueryTrimmed.isEmpty) {
      return const _KeyboardDismissibleViewport(
        child: _JournalSearchEmptyPane(
          icon: Icons.search_outlined,
          title: '輸入關鍵字，搜尋所有月份的紀錄',
        ),
      );
    }

    if (_debouncedQuery.trim() != _liveQueryTrimmed) {
      return _KeyboardDismissibleViewport(
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    final activeQuery = _debouncedQuery.trim();
    if (_initialSearchInProgress) {
      return _KeyboardDismissibleViewport(
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (_searchError != null && _entries.isEmpty) {
      return _KeyboardDismissibleViewport(
        child: _SearchErrorBody(onRetry: () => _startSearch(activeQuery)),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: _entries.isEmpty
          ? const _KeyboardDismissibleViewport(
              key: ValueKey('empty'),
              child: _JournalSearchEmptyPane(
                icon: Icons.search_off_outlined,
                title: '找不到符合的紀錄',
                subtitle: '試試其他關鍵字，或簡短一點',
              ),
            )
          : _SearchResultsList(
              key: ValueKey(activeQuery),
              controller: _scrollController,
              entries: _entries,
              accounts: accounts,
              entryIdToTagTitles: _entryIdToTagTitles,
              loadMoreInProgress: _loadMoreInProgress,
              loadMoreError: _searchError,
              onLoadMoreRetry: _loadMoreResults,
              onEntryChanged: _onEntryMutation,
              theme: theme,
            ),
    );
  }
}

class _KeyboardDismissibleViewport extends StatelessWidget {
  const _KeyboardDismissibleViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: constraints.maxHeight, child: child),
        );
      },
    );
  }
}

class _JournalSearchEmptyPane extends StatelessWidget {
  const _JournalSearchEmptyPane({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.onSurfaceVariant.withValues(
      alpha: _journalSearchEmptyIconOpacity,
    );
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final subtitleStyle = theme.textStyles.bodySmallMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: _journalSearchEmptyIconSize, color: iconColor),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: titleStyle),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: subtitleStyle),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchErrorBody extends StatelessWidget {
  const _SearchErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: _journalSearchEmptyIconSize,
              color: colorScheme.onSurfaceVariant.withValues(
                alpha: _journalSearchEmptyIconOpacity,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '無法載入搜尋結果',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('重試')),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    super.key,
    required this.controller,
    required this.entries,
    required this.accounts,
    required this.entryIdToTagTitles,
    required this.loadMoreInProgress,
    required this.loadMoreError,
    required this.onLoadMoreRetry,
    required this.onEntryChanged,
    required this.theme,
  });

  final ScrollController controller;
  final List<Map<String, Object?>> entries;
  final Map<String, Account> accounts;
  final Map<String, List<String>> entryIdToTagTitles;
  final bool loadMoreInProgress;
  final Object? loadMoreError;
  final VoidCallback onLoadMoreRetry;
  final VoidCallback onEntryChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: entries.length + 1,
      separatorBuilder: (context, _) =>
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
      itemBuilder: (context, index) {
        if (index == entries.length) {
          if (loadMoreInProgress) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (loadMoreError != null) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Center(
                child: TextButton.icon(
                  onPressed: onLoadMoreRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('載入失敗，重試'),
                ),
              ),
            );
          }
          return const SizedBox(height: 64);
        }
        final entry = entries[index];
        return _JournalSearchEntryBlock(
          entry: entry,
          accounts: accounts,
          entryIdToTagTitles: entryIdToTagTitles,
          onDataChanged: onEntryChanged,
        );
      },
    );
  }
}

class _JournalSearchEntryBlock extends StatelessWidget {
  const _JournalSearchEntryBlock({
    required this.entry,
    required this.accounts,
    required this.entryIdToTagTitles,
    required this.onDataChanged,
  });

  final Map<String, Object?> entry;
  final Map<String, Account> accounts;
  final Map<String, List<String>> entryIdToTagTitles;
  final VoidCallback onDataChanged;

  String _formatEntryDateLine() {
    final occurredAt = entry['occurred_at'] as String? ?? '';
    DateTime local;
    try {
      local = DateTime.parse(occurredAt).toLocal();
    } catch (_) {
      return '';
    }
    final datePart =
        '${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
    final weekday = chineseWeekdayLabels[local.weekday - 1];
    return '$datePart ($weekday)';
  }

  String _accessibilityAmountDescription() {
    final typeStr = entry['type'] as String? ?? 'expense';
    final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
    if (type == EntryType.income) {
      return '+${formatAmountForDisplay(amount)}';
    }
    if (type == EntryType.expense) {
      return '-${formatAmountForDisplay(amount)}';
    }
    return formatAmountForDisplay(amount);
  }

  String _accessibilityTitle() {
    final memo = entry['memo'] as String?;
    if (memo != null && memo.trim().isNotEmpty) {
      return memo.split('\n').first.trim();
    }
    final typeStr = entry['type'] as String? ?? 'expense';
    final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
    final debitId = entry['debit_account_id'] as String? ?? '';
    final creditId = entry['credit_account_id'] as String? ?? '';
    final debit = accounts[debitId];
    final credit = accounts[creditId];
    switch (type) {
      case EntryType.expense:
        return debit?.subType.isNotEmpty == true
            ? debit!.subType
            : (debit?.name ?? '支出');
      case EntryType.income:
        return credit?.subType.isNotEmpty == true
            ? credit!.subType
            : (credit?.name ?? '收入');
      default:
        return type.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLine = _formatEntryDateLine();
    final titleForSemantics = _accessibilityTitle();
    final amountDescription = _accessibilityAmountDescription();
    return Semantics(
      label: '$dateLine，$titleForSemantics，$amountDescription',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (dateLine.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  dateLine,
                  style: theme.textStyles.sectionLabel.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            EntryRow(
              entry: entry,
              accounts: accounts,
              entryTagTitles: entryIdToTagTitles,
              privacyMode: false,
              onTap: () => EntryListHandlers.openEntry(context, entry, onDataChanged),
              onDelete: () =>
                  EntryListHandlers.deleteEntry(context, entry, onDataChanged),
              onCopy: () => EntryListHandlers.copyEntry(context, entry, onDataChanged),
            ),
          ],
        ),
      ),
    );
  }
}
