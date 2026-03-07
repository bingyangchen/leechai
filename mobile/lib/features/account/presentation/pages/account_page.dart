import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/data/services/account_balance.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/account/domain/account_group_kind.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/domain/liability_type.dart';
import 'package:mobile/features/account/presentation/pages/account_detail_page.dart';
import 'package:mobile/features/account/presentation/widgets/account_group_section.dart';
import 'package:mobile/features/account/presentation/widgets/add_account_sheet.dart';
import 'package:mobile/features/account/presentation/widgets/net_worth_header.dart';
import 'package:mobile/shared/utils/refresh_snap_back.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/app_refresh_indicator.dart';
import 'package:mobile/shared/widgets/haptic_refresh_wrapper.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key, this.refreshTrigger});
  final ValueListenable<int>? refreshTrigger;

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  bool _privacyMode = false;
  late Future<_AccountPageData> _future;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    widget.refreshTrigger?.addListener(_onRefresh);
  }

  @override
  void didUpdateWidget(AssetsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefresh);
      widget.refreshTrigger?.addListener(_onRefresh);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefresh);
    _scrollController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<_AccountPageData> _loadData() async {
    final accounts = await AccountRepository.getBalanceAccounts();
    final balances = await AccountBalanceService.getBalances();
    final sparkline = await AccountBalanceService.getNetWorthSparkline();
    double totalAssets = 0;
    double totalLiabilities = 0;
    for (final a in accounts) {
      final b = balances[a.id] ?? 0;
      if (a.type == AccountType.asset) {
        totalAssets += b;
      } else {
        totalLiabilities += b;
      }
    }
    return _AccountPageData(
      accounts: accounts,
      balances: balances,
      sparkline: sparkline,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
    );
  }

  void _onAddCurrentAssets() {
    showAppBottomSheet<void>(
      context,
      mode: AppBottomSheetMode.static,
      title: '選擇帳戶類型',
      showCloseButton: false,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _TypeChip(
              label: AssetType.cash.label,
              icon: AssetType.cash.icon,
              onTap: () {
                Navigator.pop(ctx);
                _openAddAccountForm(
                  type: AccountType.asset,
                  subType: AssetType.cash.name,
                  subTypeLabel: AssetType.cash.label,
                  icon: AssetType.cash.icon,
                );
              },
            ),
            _TypeChip(
              label: AssetType.bank.label,
              icon: AssetType.bank.icon,
              onTap: () {
                Navigator.pop(ctx);
                _openAddAccountForm(
                  type: AccountType.asset,
                  subType: AssetType.bank.name,
                  subTypeLabel: AssetType.bank.label,
                  icon: AssetType.bank.icon,
                );
              },
            ),
            _TypeChip(
              label: AssetType.epayment.label,
              icon: AssetType.epayment.icon,
              onTap: () {
                Navigator.pop(ctx);
                _openAddAccountForm(
                  type: AccountType.asset,
                  subType: AssetType.epayment.name,
                  subTypeLabel: AssetType.epayment.label,
                  icon: AssetType.epayment.icon,
                );
              },
            ),
            _TypeChip(
              label: AssetType.storedValueCard.label,
              icon: AssetType.storedValueCard.icon,
              onTap: () {
                Navigator.pop(ctx);
                _openAddAccountForm(
                  type: AccountType.asset,
                  subType: AssetType.storedValueCard.name,
                  subTypeLabel: AssetType.storedValueCard.label,
                  icon: AssetType.storedValueCard.icon,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddAccountForm({
    required AccountType type,
    required String subType,
    required String subTypeLabel,
    required IconData icon,
  }) async {
    final created = await showAddAccountSheet(
      context,
      type: type,
      subType: subType,
      subTypeLabel: subTypeLabel,
      icon: icon,
    );
    if (created == true && mounted) _onRefresh();
  }

  void _onAddCreditCard() {
    _openAddAccountForm(
      type: AccountType.liability,
      subType: LiabilityType.creditCard.name,
      subTypeLabel: LiabilityType.creditCard.label,
      icon: LiabilityType.creditCard.icon,
    );
  }

  void _onAddInvestments() {
    _openAddAccountForm(
      type: AccountType.asset,
      subType: AssetType.securities.name,
      subTypeLabel: AssetType.securities.label,
      icon: AssetType.securities.icon,
    );
  }

  void _onAddLoans() {
    _openAddAccountForm(
      type: AccountType.liability,
      subType: LiabilityType.loan.name,
      subTypeLabel: LiabilityType.loan.label,
      icon: LiabilityType.loan.icon,
    );
  }

  void _onTapAccount(Account account) {
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => AccountDetailPage(accountId: account.id),
          ),
        )
        .then((_) => _onRefresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: HapticRefreshWrapper(
          child: FutureBuilder<_AccountPageData>(
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

              final currentAssets = data.accounts
                  .where(
                    (a) =>
                        a.type == AccountType.asset &&
                        _currentAssetsSubTypes.contains(a.subType),
                  )
                  .toList();
              final creditCards = data.accounts
                  .where(
                    (a) =>
                        a.type == AccountType.liability &&
                        a.subType == LiabilityType.creditCard.name,
                  )
                  .toList();
              final investments = data.accounts
                  .where(
                    (a) =>
                        a.type == AccountType.asset &&
                        a.subType == AssetType.securities.name,
                  )
                  .toList();
              final loans = data.accounts
                  .where(
                    (a) =>
                        a.type == AccountType.liability &&
                        a.subType == LiabilityType.loan.name,
                  )
                  .toList();

              final netWorth = data.totalAssets - data.totalLiabilities;

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  appSliverRefreshControl(
                    onRefresh: () =>
                        runRefreshWithSnapBack(_scrollController, () async {
                          _onRefresh();
                          await _future;
                        }),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NetWorthHeader(
                          netWorth: netWorth,
                          totalAssets: data.totalAssets,
                          totalLiabilities: data.totalLiabilities,
                          sparklinePoints: data.sparkline,
                          privacyMode: _privacyMode,
                          onPrivacyToggle: () =>
                              setState(() => _privacyMode = !_privacyMode),
                        ),
                        const SizedBox(height: 8),
                        AccountGroupSection(
                          kind: AccountGroupKind.currentAssets,
                          accounts: currentAssets,
                          balances: data.balances,
                          privacyMode: _privacyMode,
                          onAdd: _onAddCurrentAssets,
                          onTapAccount: _onTapAccount,
                        ),
                        AccountGroupSection(
                          kind: AccountGroupKind.creditCard,
                          accounts: creditCards,
                          balances: data.balances,
                          privacyMode: _privacyMode,
                          onAdd: _onAddCreditCard,
                          onTapAccount: _onTapAccount,
                        ),
                        AccountGroupSection(
                          kind: AccountGroupKind.investments,
                          accounts: investments,
                          balances: data.balances,
                          privacyMode: _privacyMode,
                          roiPercent: _mockRoi(investments, data.balances),
                          onAdd: _onAddInvestments,
                          onTapAccount: _onTapAccount,
                        ),
                        AccountGroupSection(
                          kind: AccountGroupKind.loans,
                          accounts: loans,
                          balances: data.balances,
                          privacyMode: _privacyMode,
                          onAdd: _onAddLoans,
                          onTapAccount: _onTapAccount,
                        ),
                        const SizedBox(height: 88),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static const _currentAssetsSubTypes = ['cash', 'bank', 'epayment', 'storedValueCard'];

  double? _mockRoi(List<Account> accounts, Map<String, double> balances) {
    // TODO: Implement real ROI calculation
    if (accounts.isEmpty) return null;
    return 5.2;
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 22), const SizedBox(width: 8), Text(label)],
        ),
      ),
    );
  }
}

class _AccountPageData {
  _AccountPageData({
    required this.accounts,
    required this.balances,
    required this.sparkline,
    required this.totalAssets,
    required this.totalLiabilities,
  });

  final List<Account> accounts;
  final Map<String, double> balances;
  final List<double> sparkline;
  final double totalAssets;
  final double totalLiabilities;
}
