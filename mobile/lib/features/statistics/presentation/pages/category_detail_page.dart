import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/data/repositories/tag.dart' show TagRepository;
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/entry_list_handlers.dart';
import 'package:mobile/features/entry/presentation/widgets/entry_row.dart';
import 'package:mobile/features/statistics/data/services/statistics.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/shared/theme/category_colors.dart';
import 'package:mobile/features/statistics/presentation/widgets/category_monthly_bar_chart.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({
    super.key,
    required this.subType,
    required this.isExpense,
    required this.dateRange,
    required this.privacyMode,
  });

  final String subType;
  final bool isExpense;
  final DateRange dateRange;
  final bool privacyMode;

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_DetailData> _loadData() async {
    final monthly = await StatisticsService.getCategoryMonthlyTotals(
      widget.subType,
      widget.isExpense,
      widget.dateRange.end,
    );

    final entries = await EntryRepository.getByOccurredAtDateRange(
      widget.dateRange.start,
      widget.dateRange.end,
    );
    final allAccounts = <String, Account>{};
    for (final a in await AccountRepository.getAll()) {
      allAccounts[a.id] = a;
    }

    final targetType = widget.isExpense ? EntryType.expense : EntryType.income;
    final categoryKey = widget.isExpense ? 'debit_account_id' : 'credit_account_id';
    final categoryAccountIds = allAccounts.values
        .where(
          (a) =>
              a.type == (widget.isExpense ? AccountType.expense : AccountType.income) &&
              a.subType == widget.subType,
        )
        .map((a) => a.id)
        .toSet();

    final filtered =
        entries.where((e) {
          final typeStr = e['type'] as String? ?? 'expense';
          final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
          if (type != targetType) return false;
          final catId = e[categoryKey] as String? ?? '';
          return categoryAccountIds.contains(catId);
        }).toList()..sort((a, b) {
          final at = a['occurred_at'] as String? ?? '';
          final bt = b['occurred_at'] as String? ?? '';
          return bt.compareTo(at);
        });

    final tagIds = <String>{};
    final entryTagIds = <String, List<String>>{};
    for (final e in filtered) {
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

    double total = 0;
    for (final e in filtered) {
      total += (e['amount'] as num?)?.toDouble() ?? 0.0;
    }

    return _DetailData(
      monthlyTotals: monthly,
      entries: filtered,
      accounts: allAccounts,
      entryTagTitles: entryTagTitles,
      total: total,
    );
  }

  void _onRefresh() {
    setState(() {
      _future = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(toolbarHeight: kToolbarHeight, title: Text(widget.subType)),
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CategoryMonthlyBarChart(
                  monthlyTotals: data.monthlyTotals,
                  dateRange: widget.dateRange,
                  color: colorForSubType(context, widget.subType, 0),
                  privacyMode: widget.privacyMode,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Builder(
                    builder: (context) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '選定區間 (${widget.dateRange.toRangeLabel()})',
                            style: theme.textStyles.bodySmallMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.privacyMode
                                ? '****'
                                : '\$${formatAmountForDisplay(data.total)}',
                            style: theme.textStyles.headlineEmphasis,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (data.entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('此區間尚無紀錄', style: theme.textStyles.titleMuted),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = data.entries[index];
                    return EntryRow(
                      entry: entry,
                      accounts: data.accounts,
                      entryTagTitles: data.entryTagTitles,
                      privacyMode: widget.privacyMode,
                      onTap: () =>
                          EntryListHandlers.openEntry(context, entry, _onRefresh),
                      onDelete: () =>
                          EntryListHandlers.deleteEntry(context, entry, _onRefresh),
                      onCopy: () =>
                          EntryListHandlers.copyEntry(context, entry, _onRefresh),
                    );
                  }, childCount: data.entries.length),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _DetailData {
  _DetailData({
    required this.monthlyTotals,
    required this.entries,
    required this.accounts,
    required this.entryTagTitles,
    required this.total,
  });

  final List<({DateTime month, double amount})> monthlyTotals;
  final List<Map<String, Object?>> entries;
  final Map<String, Account> accounts;
  final Map<String, List<String>> entryTagTitles;
  final double total;
}
