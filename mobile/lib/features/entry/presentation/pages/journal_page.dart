import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/data/repositories/tag.dart' show TagRepository;
import 'package:mobile/features/entry/domain/entry_aggregation.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/entry_list_handlers.dart';
import 'package:mobile/features/entry/presentation/widgets/collapsed_summary_bar.dart';
import 'package:mobile/features/entry/presentation/widgets/journal_empty_state.dart';
import 'package:mobile/features/entry/presentation/widgets/journal_top_bar.dart';
import 'package:mobile/features/entry/presentation/widgets/month_summary_card.dart';
import 'package:mobile/features/entry/presentation/widgets/sticky_date_header.dart'
    show buildDateHeaderSection, dateHeaderContent;
import 'package:mobile/features/entry/presentation/widgets/sync_indicator.dart';
import 'package:mobile/features/entry/presentation/widgets/transaction_row.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key, this.refreshTrigger});
  final ValueListenable<int>? refreshTrigger;

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  DateTime _selectedMonth = DateTime.now();
  bool _privacyMode = false;
  SyncStatus _syncStatus = SyncStatus.idle;
  final ScrollController _scrollController = ScrollController();
  static const double _summaryCardHeight = 140;
  static const double _kCollapsedSummaryBarHeight = 44;
  bool _showCollapsedSummary = false;
  late Future<_JournalData> _future;
  DateTime? _currentStickyDate;
  double _currentStickyExpense = 0;
  double _currentStickyIncome = 0;
  final Map<DateTime, GlobalKey> _headerKeys = {};
  Map<DateTime, List<Map<String, Object?>>>? _lastGrouped;
  final GlobalKey _stickyBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    _scrollController.addListener(_onScroll);
    widget.refreshTrigger?.addListener(_onRefreshTrigger);
  }

  @override
  void didUpdateWidget(JournalPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefreshTrigger);
      widget.refreshTrigger?.addListener(_onRefreshTrigger);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    widget.refreshTrigger?.removeListener(_onRefreshTrigger);
    super.dispose();
  }

  void _onScroll() {
    final show =
        _scrollController.hasClients &&
        _scrollController.offset > _summaryCardHeight - 24;
    if (show != _showCollapsedSummary) {
      setState(() => _showCollapsedSummary = show);
      if (show) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateCurrentStickyDate());
      }
    } else if (show) {
      _updateCurrentStickyDate();
    }
  }

  void _updateCurrentStickyDate() {
    final grouped = _lastGrouped;
    if (grouped == null || grouped.isEmpty) return;
    final barBox = _stickyBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (barBox == null || !barBox.hasSize) return;
    final barBottom = barBox.localToGlobal(Offset(0, barBox.size.height)).dy;
    DateTime? found;
    for (final e in grouped.entries) {
      final key = _headerKeys[e.key];
      if (key?.currentContext == null) continue;
      final box = key!.currentContext!.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top <= barBottom) found = e.key;
    }
    if (found != _currentStickyDate) {
      setState(() {
        _currentStickyDate = found;
        if (found != null) {
          _currentStickyExpense = dayExpense(grouped[found]!);
          _currentStickyIncome = dayIncome(grouped[found]!);
        }
      });
    }
  }

  Future<_JournalData> _loadData() async {
    final rawEntries = await EntryRepository.getByMonth(_selectedMonth);
    final entries = rawEntries.where((e) {
      final typeStr = e['type'] as String? ?? 'expense';
      final type = EntryType.values.asNameMap()[typeStr];
      return type != EntryType.adjustment;
    }).toList();
    final allAccounts = <String, Account>{};
    for (final a in await AccountRepository.getAll()) {
      allAccounts[a.id] = a;
    }

    final tagIds = <String>{};
    final entryTagIds = <String, List<String>>{};
    for (final e in entries) {
      final id = e['id'] as String;
      final ids = await EntryRepository.getTagIdsForEntry(id);
      entryTagIds[id] = ids;
      tagIds.addAll(ids);
    }
    final tagTitles = await TagRepository.getTitlesByIds(tagIds.toList());
    final entryTagTitles = <String, List<String>>{};
    for (final e in entryTagIds.entries) {
      entryTagTitles[e.key] = e.value
          .map((id) => tagTitles[id] ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return _JournalData(
      entries: entries,
      accounts: allAccounts,
      tagTitles: tagTitles,
      entryTagTitles: entryTagTitles,
    );
  }

  Future<void> _onRefresh() async {
    setState(() {
      _syncStatus = SyncStatus.syncing;
      // TODO: sync data from remote server
      _future = _loadData();
    });
    await _future;
    if (mounted) setState(() => _syncStatus = SyncStatus.idle);
  }

  void _onRefreshTrigger() {
    setState(() {
      _future = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            JournalTopBar(
              selectedMonth: _selectedMonth,
              onMonthSelected: (v) {
                if (!mounted) return;
                setState(() {
                  _selectedMonth = v;
                  _future = _loadData();
                });
              },
              syncStatus: _syncStatus,
              privacyMode: _privacyMode,
              onPrivacyModeToggle: () => setState(() => _privacyMode = !_privacyMode),
            ),
            if (_syncStatus == SyncStatus.syncing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  '正在與雲端同步資料...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: FutureBuilder<_JournalData>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '錯誤：${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final data = snapshot.data;
                        if (data == null) return const SizedBox.shrink();
                        final grouped = groupEntriesByDate(data.entries);
                        _lastGrouped = grouped;
                        for (final date in grouped.keys) {
                          _headerKeys.putIfAbsent(date, () => GlobalKey());
                        }
                        final summary = _computeSummary(data.entries);
                        if (data.entries.isEmpty) {
                          return CustomScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: MonthSummaryCard(
                                  income: summary.income,
                                  expense: summary.expense,
                                  balance: summary.balance,
                                  privacyMode: _privacyMode,
                                ),
                              ),
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: const JournalEmptyState(),
                              ),
                            ],
                          );
                        }
                        final dateToShow =
                            _currentStickyDate ??
                            (grouped.keys.isNotEmpty ? grouped.keys.first : null);
                        final showStickyBar =
                            _showCollapsedSummary && dateToShow != null;
                        return Stack(
                          children: [
                            CustomScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: MonthSummaryCard(
                                    income: summary.income,
                                    expense: summary.expense,
                                    balance: summary.balance,
                                    privacyMode: _privacyMode,
                                  ),
                                ),
                                for (final e in grouped.entries) ...[
                                  SliverToBoxAdapter(
                                    child: buildDateHeaderSection(
                                      key: _headerKeys[e.key],
                                      context: context,
                                      date: e.key,
                                      dayExpense: dayExpense(e.value),
                                      dayIncome: dayIncome(e.value),
                                      privacyMode: _privacyMode,
                                    ),
                                  ),
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final row = e.value[index];
                                      return TransactionRow(
                                        entry: row,
                                        accounts: data.accounts,
                                        entryTagTitles: data.entryTagTitles,
                                        privacyMode: _privacyMode,
                                        onTap: () => EntryListHandlers.openEntry(
                                          context,
                                          row,
                                          _onRefreshTrigger,
                                        ),
                                        onDelete: () => EntryListHandlers.deleteEntry(
                                          context,
                                          row,
                                          _onRefreshTrigger,
                                        ),
                                        onCopy: () => EntryListHandlers.copyEntry(
                                          context,
                                          row,
                                          _onRefreshTrigger,
                                        ),
                                      );
                                    }, childCount: e.value.length),
                                  ),
                                ],
                                const SliverPadding(
                                  padding: EdgeInsets.only(bottom: 88),
                                ),
                              ],
                            ),
                            if (showStickyBar)
                              Positioned(
                                top: _showCollapsedSummary
                                    ? _kCollapsedSummaryBarHeight
                                    : 0,
                                left: 0,
                                right: 0,
                                key: _stickyBarKey,
                                child: dateHeaderContent(
                                  context: context,
                                  date: dateToShow,
                                  dayExpense: dateToShow == _currentStickyDate
                                      ? _currentStickyExpense
                                      : dayExpense(grouped[dateToShow]!),
                                  dayIncome: dateToShow == _currentStickyDate
                                      ? _currentStickyIncome
                                      : dayIncome(grouped[dateToShow]!),
                                  privacyMode: _privacyMode,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (_showCollapsedSummary)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: CollapsedSummaryBar(
                        future: _future,
                        getSummaryText: (data) =>
                            '本月結餘 ${_privacyMode ? '****' : _formatBalance(_computeSummary((data as _JournalData).entries).balance)}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _MonthSummary _computeSummary(List<Map<String, Object?>> entries) {
    double income = 0, expense = 0;
    for (final e in entries) {
      final typeStr = e['type'] as String? ?? 'expense';
      final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
      final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
      if (type == EntryType.income) {
        income += amount;
      } else if (type == EntryType.expense) {
        expense += amount;
      }
      // transfer/borrow/repay: could add to expense/income by design; here we only count expense & income
    }
    return _MonthSummary(income: income, expense: expense, balance: income - expense);
  }

  static String _formatBalance(double v) {
    if (v >= 0) return '+${formatAmountForDisplay(v)}';
    return '-${formatAmountForDisplay(-v)}';
  }
}

class _JournalData {
  _JournalData({
    required this.entries,
    required this.accounts,
    required this.tagTitles,
    required this.entryTagTitles,
  });

  final List<Map<String, Object?>> entries;
  final Map<String, Account> accounts;
  final Map<String, String> tagTitles;
  final Map<String, List<String>> entryTagTitles;
}

class _MonthSummary {
  _MonthSummary({required this.income, required this.expense, required this.balance});
  final double income, expense, balance;
}
