import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/data/services/account_balance.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/domain/constants.dart';
import 'package:mobile/features/account/domain/liability_type.dart';
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
import 'package:mobile/shared/utils/refresh_snap_back.dart';
import 'package:mobile/shared/utils/snackbar.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/app_refresh_indicator.dart';
import 'package:mobile/shared/widgets/confirm_delete_dialog.dart';
import 'package:mobile/shared/widgets/haptic_refresh_wrapper.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  static const int _entryPageSize = 30;
  static const double _loadMoreExtentAfterThresholdPx = 640;

  bool _privacyMode = false;
  late Future<_DetailData> _future;
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

  Future<_DetailData> _loadData() async {
    _entries.clear();
    _entryIdToTagTitles.clear();
    _hasMoreEntries = true;
    _isLoadingMoreEntries = false;
    _loadMoreError = null;

    final account = await AccountRepository.getById(widget.accountId);
    if (account == null) throw StateError('Account not found: ${widget.accountId}');
    final allAccounts = <String, Account>{};
    for (final a in await AccountRepository.getAll()) {
      allAccounts[a.id] = a;
    }
    final balances = await AccountBalanceService.getBalances();
    final balance = balances[widget.accountId] ?? 0;
    final hasEntries = await EntryRepository.existsByAccountId(widget.accountId);
    final firstPage = await _loadEntryPage(offset: 0);
    _entries.addAll(firstPage.entries);
    _entryIdToTagTitles.addAll(firstPage.entryIdToTagTitles);
    _hasMoreEntries = firstPage.entries.length == _entryPageSize;

    return _DetailData(
      account: account,
      accounts: allAccounts,
      balance: balance,
      hasEntries: hasEntries,
    );
  }

  Future<_EntryPageData> _loadEntryPage({required int offset}) async {
    final entries = await EntryRepository.getByAccountIdPage(
      widget.accountId,
      limit: _entryPageSize,
      offset: offset,
    );
    final entryIds = entries.map((e) => e['id'] as String).toList();
    final entryIdToTagTitles = await EntryRepository.getTagTitlesForEntries(entryIds);
    return _EntryPageData(entries: entries, entryIdToTagTitles: entryIdToTagTitles);
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
      final page = await _loadEntryPage(offset: _entries.length);
      if (!mounted) return;
      setState(() {
        _entries.addAll(page.entries);
        _entryIdToTagTitles.addAll(page.entryIdToTagTitles);
        _hasMoreEntries = page.entries.length == _entryPageSize;
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
    final accountName =
        data.account.name ??
        (AssetTypeX.fromName(data.account.subType)?.label ??
            LiabilityTypeX.fromName(data.account.subType)?.label ??
            data.account.subType);

    final confirm = await ConfirmDeleteDialog.show(
      context,
      content: '確定要刪除 $accountName 嗎？',
    );
    if (confirm != true || !mounted) return;

    final deleted = await AccountRepository.delete(data.account.id);
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
      appBar: AppBar(
        toolbarHeight: kToolbarHeight,
        title: FutureBuilder<_DetailData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final name =
                  snapshot.data!.account.name ??
                  (AssetTypeX.fromName(snapshot.data!.account.subType)?.label ??
                      LiabilityTypeX.fromName(snapshot.data!.account.subType)?.label ??
                      snapshot.data!.account.subType);
              return Text(name);
            }
            return const Text('帳戶');
          },
        ),
        actions: [
          FutureBuilder<_DetailData>(
            future: _future,
            builder: (context, snapshot) {
              final isSecurities =
                  snapshot.data?.account.subType == AssetType.securities.name;
              if (!isSecurities) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: _onUpdateMarketValue,
                icon: const Icon(Icons.show_chart, size: 18),
                label: const Text('更新市值'),
              );
            },
          ),
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

          final grouped = groupEntriesByDate(_entries);
          if (_entries.isEmpty) {
            return HapticRefreshWrapper(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  appSliverRefreshControl(
                    onRefresh: () =>
                        runRefreshWithSnapBack(_scrollController, () async {
                          // NOTE: placebo effect
                          await Future.delayed(const Duration(milliseconds: 800));
                          _onRefresh();
                          await _future;
                        }),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100),
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
              ),
            );
          }

          return HapticRefreshWrapper(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                appSliverRefreshControl(
                  onRefresh: () => runRefreshWithSnapBack(_scrollController, () async {
                    // NOTE: placebo effect
                    await Future.delayed(const Duration(milliseconds: 800));
                    _onRefresh();
                    await _future;
                  }),
                ),
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
            ),
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
  });

  final Account account;
  final Map<String, Account> accounts;
  final double balance;
  final bool hasEntries;
}

class _EntryPageData {
  _EntryPageData({required this.entries, required this.entryIdToTagTitles});

  final List<Map<String, Object?>> entries;
  final Map<String, List<String>> entryIdToTagTitles;
}

class _MarketValueSheetContent extends StatefulWidget {
  const _MarketValueSheetContent({
    required this.currentValue,
    required this.onConfirm,
    required this.onCancel,
  });

  final double currentValue;
  final ValueChanged<double> onConfirm;
  final VoidCallback onCancel;

  @override
  State<_MarketValueSheetContent> createState() => _MarketValueSheetContentState();
}

class _MarketValueSheetContentState extends State<_MarketValueSheetContent> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatAmountForDisplay(widget.currentValue),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: const InputDecoration(
              labelText: '目前市值',
              hintText: '輸入金額',
              prefixText: '\$ ',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: widget.onCancel, child: const Text('取消')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final raw = stripAmount(_controller.text);
                  final value = double.tryParse(raw);
                  if (value != null && value >= 0) {
                    widget.onConfirm(value);
                  }
                },
                child: const Text('確定'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
