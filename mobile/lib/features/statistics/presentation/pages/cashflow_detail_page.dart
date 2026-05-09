import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/data/repositories/tag.dart' show TagRepository;
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
import 'package:mobile/features/entry/presentation/entry_list_handlers.dart';
import 'package:mobile/features/entry/presentation/widgets/entry_row.dart';
import 'package:mobile/features/statistics/data/services/statistics.dart';
import 'package:mobile/features/statistics/domain/date_range_preset.dart';
import 'package:mobile/features/statistics/presentation/widgets/category_monthly_bar_chart.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class CashflowDetailPage extends StatefulWidget {
  const CashflowDetailPage({
    super.key,
    required this.isExpense,
    required this.dateRange,
    required this.privacyMode,
  });

  final bool isExpense;
  final DateRange dateRange;
  final bool privacyMode;

  @override
  State<CashflowDetailPage> createState() => _CashflowDetailPageState();
}

class _CashflowDetailPageState extends State<CashflowDetailPage> {
  late Future<_CashflowDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_CashflowDetailData> _loadData() async {
    final monthly = await StatisticsService.getEntryTypeMonthlyTotals(
      widget.isExpense,
      widget.dateRange.end,
    );

    final entries = await EntryRepository.getByOccurredAtDateRange(
      widget.dateRange.start,
      widget.dateRange.end,
    );
    final accounts = <String, Account>{};
    for (final account in await AccountRepository.getAll()) {
      accounts[account.id] = account;
    }

    final targetType = widget.isExpense ? EntryType.expense : EntryType.income;
    final filtered =
        entries.where((entry) {
          final typeStr = entry['type'] as String? ?? 'expense';
          final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
          return type == targetType;
        }).toList()..sort((left, right) {
          final leftTime = left['occurred_at'] as String? ?? '';
          final rightTime = right['occurred_at'] as String? ?? '';
          return rightTime.compareTo(leftTime);
        });

    final tagIds = <String>{};
    final entryIdToTagIds = <String, List<String>>{};
    for (final entry in filtered) {
      final id = entry['id'] as String;
      final ids = await EntryRepository.getTagIdsForEntry(id);
      entryIdToTagIds[id] = ids;
      tagIds.addAll(ids);
    }
    final tagIdToTitle = await TagRepository.getTitlesByIds(tagIds.toList());
    final entryIdToTagTitles = <String, List<String>>{};
    for (final entry in entryIdToTagIds.entries) {
      entryIdToTagTitles[entry.key] = entry.value
          .map((id) => tagIdToTitle[id] ?? '')
          .where((title) => title.isNotEmpty)
          .toList();
    }

    var total = 0.0;
    for (final entry in filtered) {
      total += (entry['amount'] as num?)?.toDouble() ?? 0.0;
    }

    return _CashflowDetailData(
      monthlyTotals: monthly,
      entries: filtered,
      accounts: accounts,
      entryIdToTagTitles: entryIdToTagTitles,
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
    final title = widget.isExpense ? '支出總覽' : '收入總覽';
    final emptyLabel = widget.isExpense ? '此區間尚無支出紀錄' : '此區間尚無收入紀錄';

    return Scaffold(
      appBar: AppBar(toolbarHeight: kToolbarHeight, title: Text(title)),
      body: FutureBuilder<_CashflowDetailData>(
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
                  color: EntryTypeColors.forType(
                    context,
                    widget.isExpense ? EntryType.expense : EntryType.income,
                  ),
                  privacyMode: widget.privacyMode,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
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
                        Text(emptyLabel, style: theme.textStyles.titleMuted),
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
                      entryTagTitles: data.entryIdToTagTitles,
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

class _CashflowDetailData {
  _CashflowDetailData({
    required this.monthlyTotals,
    required this.entries,
    required this.accounts,
    required this.entryIdToTagTitles,
    required this.total,
  });

  final List<({DateTime month, double amount})> monthlyTotals;
  final List<Map<String, Object?>> entries;
  final Map<String, Account> accounts;
  final Map<String, List<String>> entryIdToTagTitles;
  final double total;
}
