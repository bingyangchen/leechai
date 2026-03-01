import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/data/services/account_balance.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/domain/liability_type.dart';
import 'package:mobile/features/account/presentation/widgets/add_account_sheet.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/data/repositories/tag.dart' show TagRepository;
import 'package:mobile/features/entry/domain/entry_aggregation.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/entry_list_handlers.dart';
import 'package:mobile/features/entry/presentation/widgets/sticky_date_header.dart'
    show buildDateHeaderSection;
import 'package:mobile/features/entry/presentation/widgets/transaction_row.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  bool _privacyMode = false;
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_DetailData> _loadData() async {
    final account = await AccountRepository.getById(widget.accountId);
    if (account == null) throw StateError('Account not found: ${widget.accountId}');
    final entries = await EntryRepository.getByAccountId(widget.accountId);
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
    final balances = await AccountBalanceService.getBalances();
    final balance = balances[widget.accountId] ?? 0;

    return _DetailData(
      account: account,
      entries: entries,
      accounts: allAccounts,
      entryTagTitles: entryTagTitles,
      balance: balance,
    );
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
    final newValue = await showDialog<double>(
      context: context,
      builder: (ctx) => _MarketValueDialog(currentValue: oldBalance),
    );
    if (newValue == null || !mounted) return;
    final diff = newValue - oldBalance;
    if (diff == 0) return;

    const incomeAccountId = 'default_income_2';
    const expenseAccountId = 'default_expense_5';
    final accountId = data.account.id;

    if (diff > 0) {
      await EntryRepository.insert(
        type: EntryType.income.name,
        debitAccountId: accountId,
        creditAccountId: incomeAccountId,
        amount: diff,
        tagIds: [],
        memo: '市值更新（未實現損益）',
        occurredAt: DateTime.now(),
      );
    } else {
      await EntryRepository.insert(
        type: EntryType.expense.name,
        debitAccountId: expenseAccountId,
        creditAccountId: accountId,
        amount: -diff,
        tagIds: [],
        memo: '市值更新（未實現損益）',
        occurredAt: DateTime.now(),
      );
    }
    if (mounted) {
      _onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            diff > 0
                ? '已記錄未實現損益 +${formatAmountForDisplay(diff)}'
                : '已記錄未實現損益 ${formatAmountForDisplay(diff)}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onOpenSettings() async {
    final data = await _future;
    if (!mounted) return;
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
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              '刪除帳戶',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(ctx);
              if (data.entries.isEmpty) {
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
      hasEntries: data.entries.isNotEmpty,
    );
    if (updated == true && mounted) _onRefresh();
  }

  Future<void> _onDeleteAccount(_DetailData data) async {
    final accountName =
        data.account.name ??
        (AssetTypeX.fromName(data.account.subType)?.label ??
            LiabilityTypeX.fromName(data.account.subType)?.label ??
            data.account.subType);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除 $accountName 嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final deleted = await AccountRepository.delete(data.account.id);
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('帳戶已刪除'), behavior: SnackBarBehavior.floating),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('此帳戶已有交易紀錄，無法刪除'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          if (snapshot.hasError) {
            return Center(
              child: Text('錯誤：${snapshot.error}', textAlign: TextAlign.center),
            );
          }
          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();

          final grouped = groupEntriesByDate(data.entries);
          if (data.entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '此帳戶尚無交易紀錄',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _onRefresh();
              await _future;
            },
            child: CustomScrollView(
              slivers: [
                for (final e in grouped.entries) ...[
                  SliverToBoxAdapter(
                    child: buildDateHeaderSection(
                      context: context,
                      date: e.key,
                      dayExpense: dayExpense(e.value),
                      dayIncome: dayIncome(e.value),
                      privacyMode: _privacyMode,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final row = e.value[index];
                      return TransactionRow(
                        entry: row,
                        accounts: data.accounts,
                        entryTagTitles: data.entryTagTitles,
                        privacyMode: _privacyMode,
                        onTap: () => EntryListHandlers.openEntry(
                          context,
                          row['id'] as String,
                          _onRefresh,
                        ),
                        onDelete: () => EntryListHandlers.deleteEntry(
                          context,
                          row['id'] as String,
                          _onRefresh,
                        ),
                        onCopy: () => EntryListHandlers.copyEntry(
                          context,
                          row['id'] as String,
                          _onRefresh,
                        ),
                      );
                    }, childCount: e.value.length),
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

class _DetailData {
  _DetailData({
    required this.account,
    required this.entries,
    required this.accounts,
    required this.entryTagTitles,
    required this.balance,
  });

  final Account account;
  final List<Map<String, Object?>> entries;
  final Map<String, Account> accounts;
  final Map<String, List<String>> entryTagTitles;
  final double balance;
}

class _MarketValueDialog extends StatefulWidget {
  const _MarketValueDialog({required this.currentValue});

  final double currentValue;

  @override
  State<_MarketValueDialog> createState() => _MarketValueDialogState();
}

class _MarketValueDialogState extends State<_MarketValueDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatAmountForDisplay(widget.currentValue),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('更新市值'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
        decoration: const InputDecoration(
          labelText: '目前市值',
          hintText: '輸入金額',
          prefixText: '\$ ',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final raw = stripAmount(_controller.text);
            final value = double.tryParse(raw);
            if (value != null && value >= 0) {
              Navigator.of(context).pop(value);
            }
          },
          child: const Text('確定'),
        ),
      ],
    );
  }
}
