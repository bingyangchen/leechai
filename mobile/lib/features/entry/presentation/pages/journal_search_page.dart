import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/services/journal_search.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/domain/journal_entry_search.dart';
import 'package:mobile/features/entry/domain/journal_search_context.dart';
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
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  String _debouncedQuery = '';
  JournalSearchContext? _context;
  Object? _loadError;
  bool _loadInProgress = false;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
    widget.refreshTrigger?.addListener(_onExternalRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
    _loadContext();
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
    _loadContext();
  }

  void _onQueryChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _debouncedQuery = _queryController.text;
      });
    });
    setState(() {});
  }

  void _onEntryMutation() {
    widget.onDataChanged();
    _loadContext();
  }

  Future<void> _loadContext() async {
    setState(() {
      _loadInProgress = true;
      _loadError = null;
    });
    try {
      final loaded = await JournalSearchService.loadContext();
      if (!mounted) return;
      setState(() {
        _context = loaded;
        _loadInProgress = false;
        _loadError = null;
      });
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('JournalSearchPage load failed: $error\n$stackTrace');
      }
      if (!mounted) return;
      setState(() {
        _loadInProgress = false;
        _loadError = error;
      });
    }
  }

  void _clearQuery() {
    _debounceTimer?.cancel();
    _queryController.clear();
    setState(() => _debouncedQuery = '');
    _searchFocusNode.requestFocus();
  }

  List<Map<String, Object?>> _filteredEntriesForQuery(String query) {
    final context = _context;
    if (context == null) return [];
    return filterJournalEntriesBySearchQuery(context: context, query: query);
  }

  String get _liveQueryTrimmed => _queryController.text.trim();

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onExternalRefresh);
    _debounceTimer?.cancel();
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
      return _SearchErrorBody(onRetry: _loadContext);
    }
    if (_loadInProgress && _context == null) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }
    final searchContext = _context;
    if (searchContext == null) {
      return const SizedBox.shrink();
    }

    if (_liveQueryTrimmed.isEmpty) {
      return const _JournalSearchEmptyPane(
        icon: Icons.search_outlined,
        title: '輸入關鍵字，搜尋所有月份的紀錄',
      );
    }

    if (_debouncedQuery.trim() != _liveQueryTrimmed) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }

    final activeQuery = _debouncedQuery.trim();
    final filtered = _filteredEntriesForQuery(activeQuery);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: filtered.isEmpty
          ? const _JournalSearchEmptyPane(
              key: ValueKey('empty'),
              icon: Icons.search_off_outlined,
              title: '找不到符合的紀錄',
              subtitle: '試試其他關鍵字，或簡短一點',
            )
          : _SearchResultsList(
              key: ValueKey(activeQuery),
              entries: filtered,
              accounts: searchContext.accounts,
              entryTagTitles: searchContext.entryTagTitles,
              onEntryChanged: _onEntryMutation,
              theme: theme,
            ),
    );
  }
}

class _JournalSearchEmptyPane extends StatelessWidget {
  const _JournalSearchEmptyPane({
    super.key,
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
    required this.entries,
    required this.accounts,
    required this.entryTagTitles,
    required this.onEntryChanged,
    required this.theme,
  });

  final List<Map<String, Object?>> entries;
  final Map<String, Account> accounts;
  final Map<String, List<String>> entryTagTitles;
  final VoidCallback onEntryChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: entries.length,
      separatorBuilder: (context, _) =>
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _JournalSearchEntryBlock(
          entry: entry,
          accounts: accounts,
          entryTagTitles: entryTagTitles,
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
    required this.entryTagTitles,
    required this.onDataChanged,
  });

  final Map<String, Object?> entry;
  final Map<String, Account> accounts;
  final Map<String, List<String>> entryTagTitles;
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
              entryTagTitles: entryTagTitles,
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
