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
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/refresh_snap_back.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/app_refresh_indicator.dart';
import 'package:mobile/shared/widgets/haptic_refresh_wrapper.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, this.refreshTrigger});
  final ValueListenable<int>? refreshTrigger;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _privacyMode = false;
  late Future<_AccountPageData> _future;
  final ScrollController _scrollController = ScrollController();
  double _headerCollapseProgress = 0;
  static const double _headerCollapseDistance = 72;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    widget.refreshTrigger?.addListener(_onRefresh);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(AccountPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefresh);
      widget.refreshTrigger?.addListener(_onRefresh);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefresh);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    setState(() {
      _future = _loadData();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final rawCollapseProgress = (_scrollController.offset / _headerCollapseDistance)
        .clamp(0.0, 1.0);
    final nextCollapseProgress = Curves.easeOutCubic.transform(rawCollapseProgress);
    if ((nextCollapseProgress - _headerCollapseProgress).abs() < 0.001) {
      return;
    }
    setState(() {
      _headerCollapseProgress = nextCollapseProgress;
    });
  }

  Future<_AccountPageData> _loadData() async {
    final accounts = await AccountRepository.getBalanceAccounts();
    final balances = await AccountBalanceService.getBalances();
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NetWorthHeader(
                    netWorth: netWorth,
                    totalAssets: data.totalAssets,
                    totalLiabilities: data.totalLiabilities,
                    accountCount: data.accounts.length,
                    privacyMode: _privacyMode,
                    onPrivacyToggle: () => setState(() => _privacyMode = !_privacyMode),
                    collapseProgress: _headerCollapseProgress,
                  ),
                  Expanded(
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
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
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outlineSoft = theme.colorScheme.outline.withValues(alpha: 0.28);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: outlineSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(label, style: theme.textStyles.title),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountPageData {
  _AccountPageData({
    required this.accounts,
    required this.balances,
    required this.totalAssets,
    required this.totalLiabilities,
  });

  final List<Account> accounts;
  final Map<String, double> balances;
  final double totalAssets;
  final double totalLiabilities;
}
