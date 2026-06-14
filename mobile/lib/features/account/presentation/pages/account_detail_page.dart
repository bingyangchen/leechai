import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/data/services/account_balance.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/domain/constants.dart';
import 'package:mobile/features/account/presentation/widgets/account_summary_header.dart';
import 'package:mobile/features/account/presentation/widgets/add_account_sheet.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/domain/entry_aggregation.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/entry_list_handlers.dart';
import 'package:mobile/features/entry/presentation/widgets/entry_row.dart';
import 'package:mobile/features/entry/presentation/widgets/sticky_date_header.dart'
    show buildDateHeaderSection;
import 'package:mobile/features/profile/data/services/achievement.dart';
import 'package:mobile/shared/scopes/data_refresh.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/snackbar.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/confirm_delete_dialog.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  static const int _entryBatchSize = 30;
  static const double _loadMoreExtentAfterThresholdPx = 640;

  bool _privacyMode = false;
  late Future<_DetailData> _future;
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, Object?>> _entries = [];
  final Map<String, List<String>> _entryIdToTagTitles = {};
  bool _hasMoreEntries = true;
  bool _isLoadingInitialEntries = false;
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

  Future<_DetailData> _loadData() async {
    _isLoadingInitialEntries = true;
    _isLoadingMoreEntries = false;
    _loadMoreError = null;

    try {
      final account = await AccountRepository.getById(widget.accountId);
      if (account == null) throw StateError('Account not found: ${widget.accountId}');
      final allAccounts = <String, Account>{};
      for (final a in await AccountRepository.getAll()) {
        allAccounts[a.id] = a;
      }
      final balances = await AccountBalanceService.getBalances();
      final balance = balances[widget.accountId] ?? 0;
      final hasEntries = await EntryRepository.existsByAccountId(widget.accountId);
      final firstBatch = await _loadEntryBatch(offset: 0);

      _entries.clear();
      _entryIdToTagTitles.clear();
      _entries.addAll(firstBatch.entries);
      _entryIdToTagTitles.addAll(firstBatch.entryIdToTagTitles);
      _hasMoreEntries = firstBatch.entries.length == _entryBatchSize;

      final List<({DateTime date, double balance})> balanceHistory = [];
      final isSecurities = account.subType == AssetType.securities.name;

      if (isSecurities) {
        final chronological = await EntryRepository.getHistoryByAccountId(
          widget.accountId,
        );
        final Map<String, ({DateTime date, double balance})> dailyBalances = {};

        double runningBalance = account.initialBalance;
        if (chronological.isNotEmpty) {
          final firstEntryDate = DateTime.parse(
            chronological.first['occurred_at'] as String,
          ).toLocal();
          final dayBefore = DateTime(
            firstEntryDate.year,
            firstEntryDate.month,
            firstEntryDate.day,
          ).subtract(const Duration(days: 1));
          final dayBeforeKey =
              '${dayBefore.year}-${dayBefore.month.toString().padLeft(2, '0')}-${dayBefore.day.toString().padLeft(2, '0')}';
          dailyBalances[dayBeforeKey] = (date: dayBefore, balance: runningBalance);
        }

        for (final e in chronological) {
          final occurredAtStr = e['occurred_at'] as String;
          final occurredAt = DateTime.parse(occurredAtStr).toLocal();
          final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
          final debitId = e['debit_account_id'] as String? ?? '';
          final creditId = e['credit_account_id'] as String? ?? '';

          if (account.id == debitId) {
            if (account.type == AccountType.asset) {
              runningBalance += amount;
            } else {
              runningBalance -= amount;
            }
          }
          if (account.id == creditId) {
            if (account.type == AccountType.asset) {
              runningBalance -= amount;
            } else {
              runningBalance += amount;
            }
          }

          final dayKey =
              '${occurredAt.year}-${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}';
          dailyBalances[dayKey] = (
            date: DateTime(occurredAt.year, occurredAt.month, occurredAt.day),
            balance: runningBalance,
          );
        }

        balanceHistory.addAll(
          dailyBalances.values.toList()..sort((a, b) => a.date.compareTo(b.date)),
        );
      }

      if (balanceHistory.isEmpty) {
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);
        balanceHistory.add((date: todayNormalized, balance: account.initialBalance));
      }

      return _DetailData(
        account: account,
        accounts: allAccounts,
        balance: balance,
        hasEntries: hasEntries,
        balanceHistory: balanceHistory,
      );
    } finally {
      _isLoadingInitialEntries = false;
    }
  }

  Future<_EntryBatchData> _loadEntryBatch({required int offset}) async {
    final entries = await EntryRepository.getByAccountIdBatch(
      widget.accountId,
      limit: _entryBatchSize,
      offset: offset,
    );
    final entryIds = entries.map((e) => e['id'] as String).toList();
    final entryIdToTagTitles = await EntryRepository.getTagTitlesForEntries(entryIds);
    return _EntryBatchData(entries: entries, entryIdToTagTitles: entryIdToTagTitles);
  }

  void _maybeLoadMoreEntries() {
    if (!_scrollController.hasClients ||
        !_hasMoreEntries ||
        _isLoadingInitialEntries ||
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

  Future<void> _onUpdateMarketValue() async {
    final data = await _future;
    if (!mounted) return;
    final oldBalance = data.balance;
    final newValue = await showAppBottomSheet<double?>(
      context,
      title: '更新市值',
      showCloseButton: false,
      mode: AppBottomSheetMode.static,
      builder: (ctx) => _MarketValueSheetContent(
        account: data.account,
        currentValue: oldBalance,
        onConfirm: (value) => Navigator.of(ctx).pop(value),
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
    if (newValue == null || !mounted) return;
    final diff = newValue - oldBalance;
    if (diff == 0) return;

    final accountId = data.account.id;

    final now = DateTime.now();
    if (diff > 0) {
      await EntryRepository.insert(
        type: EntryType.adjustment.name,
        debitAccountId: accountId,
        creditAccountId: defaultEquityUnrealizedGainId,
        amount: diff,
        tagIds: [],
        memo: '市值更新',
        occurredAt: now,
      );
    } else {
      await EntryRepository.insert(
        type: EntryType.adjustment.name,
        debitAccountId: defaultEquityUnrealizedGainId,
        creditAccountId: accountId,
        amount: -diff,
        tagIds: [],
        memo: '市值更新',
        occurredAt: now,
      );
    }
    await AchievementService.evaluateAfterEntryInserted(
      type: EntryType.adjustment.name,
      occurredAt: now,
      tagIds: [],
      amount: diff.abs(),
    );
    if (mounted) {
      _onRefresh();
      DataRefreshScope.notify(context);
      showReplacingSnackBar(
        context,
        SnackBar(
          content: Text('已記錄未實現損益 \$${formatAmountForDisplay(diff)}'),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }
  }

  Future<void> _onOpenSettings() async {
    final data = await _future;
    if (!mounted) return;
    final theme = Theme.of(context);
    await showAppBottomSheet<void>(
      context,
      mode: AppBottomSheetMode.static,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('編輯帳戶'),
            onTap: () {
              Navigator.pop(ctx);
              _onEditAccount(data);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text(
              '刪除帳戶',
              style: theme.textStyles.bodyLargeMuted.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            onTap: () {
              Navigator.pop(ctx);
              if (!data.hasEntries) {
                _onDeleteAccount(data);
              } else {
                showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('無法刪除'),
                    content: const Text('此帳戶已有交易紀錄，為確保帳務正確，請先刪除紀錄。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('確定'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onEditAccount(_DetailData data) async {
    final updated = await showAccountFormSheet(
      context,
      existingAccount: data.account,
      hasEntries: data.hasEntries,
    );
    if (updated == true && mounted) _onRefresh();
  }

  Future<void> _onDeleteAccount(_DetailData data) async {
    final accountName = data.account.displayName;

    final confirm = await ConfirmDeleteDialog.show(
      context,
      content: '確定要刪除 $accountName 嗎？',
    );
    if (confirm != true || !mounted) return;

    final deleted = await AccountRepository.softDelete(data.account.id);
    if (!mounted) return;
    if (deleted) {
      final accountId = data.account.id;
      final messenger = ScaffoldMessenger.of(context);
      final overlayContext = Navigator.of(context).overlay?.context;
      showReplacingSnackBarForMessenger(
        messenger,
        SnackBar(
          content: const Text('帳戶已刪除'),
          duration: const Duration(seconds: 4),
          persist: false,
          action: SnackBarAction(
            label: '復原',
            onPressed: () async {
              await AccountRepository.restore(accountId);
              if (overlayContext != null && overlayContext.mounted) {
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
      Navigator.of(context).pop();
    } else {
      final theme = Theme.of(context);
      showReplacingSnackBar(
        context,
        SnackBar(
          content: Text(
            '此帳戶已有交易紀錄，無法刪除',
            style: TextStyle(color: theme.colorScheme.onError),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: kToolbarHeight,
        title: FutureBuilder<_DetailData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!.account.displayName);
            }
            return const Text('帳戶');
          },
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _privacyMode = !_privacyMode),
            icon: Icon(
              _privacyMode ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            ),
            tooltip: _privacyMode ? '顯示金額' : '隱藏金額',
          ),
          IconButton(
            onPressed: _onOpenSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
          ),
        ],
      ),
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();
          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMoreEntries());

          final topPadding = MediaQuery.of(context).padding.top + 28;
          final isSecurities = data.account.subType == AssetType.securities.name;
          final hasChart = isSecurities && data.balanceHistory.length >= 2;
          final headerHeight = (hasChart ? 196.0 : 80.0) + topPadding;

          Widget scrollContent;
          final grouped = groupEntriesByDate(_entries);
          if (_entries.isEmpty) {
            scrollContent = CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: headerHeight)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: SizedBox(
                      height: 400,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: theme.colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text('此帳戶尚無交易紀錄', style: theme.textStyles.titleMuted),
                          if (_isLoadingMoreEntries) ...[
                            const SizedBox(height: 20),
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            scrollContent = CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: headerHeight)),
                for (final e in grouped.entries) ...[
                  SliverToBoxAdapter(
                    child: buildDateHeaderSection(
                      date: e.key,
                      dayExpense: dayExpense(e.value),
                      dayIncome: dayIncome(e.value),
                      privacyMode: _privacyMode,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final row = e.value[index];
                      return EntryRow(
                        entry: row,
                        accounts: data.accounts,
                        entryTagTitles: _entryIdToTagTitles,
                        privacyMode: _privacyMode,
                        perspectiveAccountId: data.account.id,
                        onTap: () =>
                            EntryListHandlers.openEntry(context, row, _onRefresh),
                        onDelete: () =>
                            EntryListHandlers.deleteEntry(context, row, _onRefresh),
                        onCopy: () =>
                            EntryListHandlers.copyEntry(context, row, _onRefresh),
                      );
                    }, childCount: e.value.length),
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
                const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
              ],
            );
          }

          return Stack(
            children: [
              // Layer 2: Scrollable content (List of Entries)
              Positioned.fill(child: scrollContent),

              // Layer 1: Background Mural with parallax, fade and dynamic clip height (On top for tap/scroll interactivity!)
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  final scrollOffset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0.0;
                  final translateY = -scrollOffset * 0.3;
                  final opacity = (1.0 - scrollOffset / 300.0).clamp(0.0, 1.0);
                  final visibleHeight = (headerHeight - scrollOffset).clamp(
                    0.0,
                    double.infinity,
                  );

                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: visibleHeight,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: headerHeight,
                        maxHeight: headerHeight,
                        child: Transform.translate(
                          offset: Offset(0, translateY),
                          child: Opacity(opacity: opacity, child: child),
                        ),
                      ),
                    ),
                  );
                },
                child: AccountSummaryHeader(
                  account: data.account,
                  balance: data.balance,
                  privacyMode: _privacyMode,
                  balanceHistory: data.balanceHistory,
                  topPadding: topPadding,
                  onUpdateMarketValue: _onUpdateMarketValue,
                ),
              ),

              // Layer 3: Custom AppBar background fading in
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  final scrollOffset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0.0;
                  final opacity = ((scrollOffset - 40) / 60).clamp(0.0, 1.0);

                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).padding.top,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: opacity),
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outline.withValues(
                              alpha: opacity * 0.12,
                            ),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailData {
  _DetailData({
    required this.account,
    required this.accounts,
    required this.balance,
    required this.hasEntries,
    required this.balanceHistory,
  });

  final Account account;
  final Map<String, Account> accounts;
  final double balance;
  final bool hasEntries;
  final List<({DateTime date, double balance})> balanceHistory;
}

class _EntryBatchData {
  _EntryBatchData({required this.entries, required this.entryIdToTagTitles});

  final List<Map<String, Object?>> entries;
  final Map<String, List<String>> entryIdToTagTitles;
}

class _MarketValueSheetContent extends StatefulWidget {
  const _MarketValueSheetContent({
    required this.account,
    required this.currentValue,
    required this.onConfirm,
    required this.onCancel,
  });

  final Account account;
  final double currentValue;
  final ValueChanged<double> onConfirm;
  final VoidCallback onCancel;

  @override
  State<_MarketValueSheetContent> createState() => _MarketValueSheetContentState();
}

class _MarketValueSheetContentState extends State<_MarketValueSheetContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatAmountForDisplay(widget.currentValue),
    );
    _controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      if (_controller.text.isNotEmpty) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _accountName => widget.account.displayName;

  double? get _value {
    final raw = stripAmount(_controller.text);
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  double? get _diff {
    final value = _value;
    if (value == null) return null;
    return value - widget.currentValue;
  }

  String get _diffLabel {
    final diff = _diff;
    if (diff == null) return '輸入新市值後會自動計算差額';
    if (diff == 0) return '市值尚未變動';
    final sign = diff > 0 ? '+' : '-';
    return '未實現損益 $sign\$${formatAmountForDisplay(diff.abs())}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final value = _value;
    if (value == null || value == widget.currentValue) return;
    widget.onConfirm(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountingColors = AccountingColors.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final diff = _diff;
    final diffColor = diff == null || diff == 0
        ? theme.colorScheme.onSurfaceVariant
        : diff > 0
        ? accountingColors.income
        : accountingColors.expense;
    final canSubmit = _value != null && _value! >= 0 && _value != widget.currentValue;

    return Form(
      key: _formKey,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.account.displayIcon,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _accountName,
                          style: theme.textStyles.titleEmphasis,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '目前帳面值 \$${formatAmountForDisplay(widget.currentValue)}',
                          style: theme.textStyles.bodySmallMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('新的市值', style: theme.textStyles.titleMuted),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixText: '\$ ',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: theme.textStyles.headline.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.right,
                autofocus: true,
                validator: (value) {
                  final raw = value == null ? '' : stripAmount(value);
                  if (raw.isEmpty) return '請輸入目前市值';
                  final amount = double.tryParse(raw);
                  if (amount == null || amount < 0) return '請輸入有效金額';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      diff == null || diff == 0
                          ? Icons.horizontal_rule
                          : diff > 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: diffColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _diffLabel,
                        style: theme.textStyles.body.copyWith(color: diffColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canSubmit ? _submit : null,
                  child: const Text('記錄市值更新'),
                ),
              ),
              TextButton(onPressed: widget.onCancel, child: const Text('取消')),
            ],
          ),
        ),
      ),
    );
  }
}
