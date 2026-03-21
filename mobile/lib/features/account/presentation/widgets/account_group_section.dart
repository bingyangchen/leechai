import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/account/domain/account_group_kind.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/domain/liability_type.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class AccountGroupSection extends StatelessWidget {
  const AccountGroupSection({
    super.key,
    required this.kind,
    required this.accounts,
    required this.balances,
    required this.privacyMode,
    required this.onAdd,
    required this.onTapAccount,
  });

  final AccountGroupKind kind;
  final List<Account> accounts;
  final Map<String, double> balances;
  final bool privacyMode;
  final VoidCallback onAdd;
  final void Function(Account account) onTapAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = accounts.fold<double>(0, (sum, a) => sum + (balances[a.id] ?? 0));
    final displayTotal = kind.isLiability ? total.abs() : total;
    final totalStr = privacyMode ? '****' : formatAmountForDisplay(displayTotal);

    final cardRadius = BorderRadius.circular(12);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: cardRadius,
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(
            dividerColor: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            controlAffinity: ListTileControlAffinity.leading,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: cardRadius),
            collapsedShape: RoundedRectangleBorder(borderRadius: cardRadius),
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0),
            collapsedBackgroundColor: theme.colorScheme.surface.withValues(alpha: 0),
            title: Row(
              children: [
                Icon(kind.sectionIcon, color: _sectionColor(context), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(kind.title, style: theme.textStyles.titleEmphasis),
                ),
                if (kind == AccountGroupKind.creditCard)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('未繳金額', style: theme.textStyles.bodySmallMuted),
                  ),
                if (kind == AccountGroupKind.investments)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('市值', style: theme.textStyles.bodySmallMuted),
                  ),
                Text(
                  '\$$totalStr',
                  style: theme.textStyles.titleEmphasis.copyWith(
                    color: kind.isLiability ? _liabilityAmountColor(context) : null,
                  ),
                ),
              ],
            ),
            children: [
              ...accounts.map(
                (a) => _AccountListTile(
                  account: a,
                  balance: balances[a.id] ?? 0,
                  isLiability: kind.isLiability,
                  privacyMode: privacyMode,
                  onTap: () => onTapAccount(a),
                ),
              ),
              _AddAccountListTile(label: kind.addButtonLabel, onTap: onAdd),
            ],
          ),
        ),
      ),
    );
  }

  Color _sectionColor(BuildContext context) {
    final c = AccountingColors.of(context);
    switch (kind) {
      case AccountGroupKind.currentAssets:
        return c.income;
      case AccountGroupKind.creditCard:
        return c.expense;
      case AccountGroupKind.investments:
        return c.transfer;
      case AccountGroupKind.loans:
        return c.neutral;
    }
  }

  Color _liabilityAmountColor(BuildContext context) {
    return AccountingColors.of(context).liability;
  }
}

class _AddAccountListTile extends StatelessWidget {
  const _AddAccountListTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.35)),
        ),
        child: Icon(Icons.add, color: theme.colorScheme.onSurfaceVariant, size: 24),
      ),
      title: Text(label, style: theme.textStyles.bodyLargeMuted),
    );
  }
}

class _AccountListTile extends StatelessWidget {
  const _AccountListTile({
    required this.account,
    required this.balance,
    required this.isLiability,
    required this.privacyMode,
    required this.onTap,
  });

  final Account account;
  final double balance;
  final bool isLiability;
  final bool privacyMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayBalance = isLiability ? balance.abs() : balance;
    final amountStr = privacyMode ? '****' : formatAmountForDisplay(displayBalance);
    final icon = _iconForAccount(account);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 24),
      ),
      title: Text(account.name ?? _defaultName(account), style: theme.textStyles.title),
      trailing: Text(
        '\$$amountStr',
        style: theme.textStyles.titleSmallEmphasis.copyWith(
          color: isLiability ? AccountingColors.of(context).liability : null,
        ),
      ),
    );
  }

  IconData _iconForAccount(Account account) {
    if (account.icon != null) return account.icon!;
    final at = AssetTypeX.fromName(account.subType);
    if (at != null) return at.icon;
    final lt = LiabilityTypeX.fromName(account.subType);
    if (lt != null) return lt.icon;
    return account.displayIcon;
  }

  String _defaultName(Account account) {
    final at = AssetTypeX.fromName(account.subType);
    if (at != null) return at.label;
    final lt = LiabilityTypeX.fromName(account.subType);
    if (lt != null) return lt.label;
    return account.subType.isNotEmpty ? account.subType : '帳戶';
  }
}
