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
    final initiallyExpanded = _isPrimarySection || accounts.isNotEmpty;
    final sectionColor = _sectionColor(context);

    if (accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Column(
          children: [
            _AccountGroupHeader(
              kind: kind,
              totalText: totalStr,
              sectionColor: sectionColor,
            ),
            const SizedBox(height: 8),
            _AddAccountListTile(
              label: _emptyAddButtonLabel,
              sectionColor: sectionColor,
              onTap: onAdd,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(
            dividerColor: theme.colorScheme.outline.withValues(alpha: 0),
          ),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0),
            collapsedBackgroundColor: theme.colorScheme.surface.withValues(alpha: 0),
            iconColor: theme.colorScheme.onSurfaceVariant,
            collapsedIconColor: theme.colorScheme.onSurfaceVariant.withValues(
              alpha: 0.72,
            ),
            title: _AccountGroupHeader(
              kind: kind,
              totalText: totalStr,
              sectionColor: sectionColor,
            ),
            children: [
              for (final account in accounts) ...[
                _AccountListTile(
                  account: account,
                  balance: balances[account.id] ?? 0,
                  isLiability: kind.isLiability,
                  privacyMode: privacyMode,
                  onTap: () => onTapAccount(account),
                ),
                const SizedBox(height: 6),
              ],
              _AddAccountListTile(
                label: kind.addButtonLabel,
                sectionColor: sectionColor,
                onTap: onAdd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isPrimarySection {
    return kind == AccountGroupKind.currentAssets ||
        kind == AccountGroupKind.creditCard;
  }

  String get _emptyAddButtonLabel {
    switch (kind) {
      case AccountGroupKind.currentAssets:
        return '新增第一個帳戶';
      case AccountGroupKind.creditCard:
        return '新增第一張信用卡';
      case AccountGroupKind.investments:
        return '新增第一個投資帳戶';
      case AccountGroupKind.loans:
        return '新增第一個貸款帳戶';
    }
  }

  Color _sectionColor(BuildContext context) {
    final theme = Theme.of(context);
    final accountingColors = AccountingColors.of(context);
    switch (kind) {
      case AccountGroupKind.currentAssets:
        return theme.colorScheme.primary;
      case AccountGroupKind.creditCard:
        return accountingColors.liability;
      case AccountGroupKind.investments:
        return ChartPalette.of(context).palette[2];
      case AccountGroupKind.loans:
        return Color.lerp(
          accountingColors.liability,
          theme.colorScheme.onSurfaceVariant,
          0.32,
        )!;
    }
  }
}

class _AccountGroupHeader extends StatelessWidget {
  const _AccountGroupHeader({
    required this.kind,
    required this.totalText,
    required this.sectionColor,
  });

  final AccountGroupKind kind;
  final String totalText;
  final Color sectionColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = kind.isLiability
        ? AccountingColors.of(context).liability
        : theme.colorScheme.onSurface;
    final descriptor = switch (kind) {
      AccountGroupKind.creditCard => '未繳',
      AccountGroupKind.investments => '市值',
      AccountGroupKind.loans => '未還',
      AccountGroupKind.currentAssets => null,
    };
    final amountText = descriptor == null ? '\$$totalText' : '$descriptor \$$totalText';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: sectionColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(kind.sectionIcon, color: sectionColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                kind.title,
                style: theme.textStyles.sectionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                amountText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textStyles.titleSmallEmphasis.copyWith(color: amountColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddAccountListTile extends StatelessWidget {
  const _AddAccountListTile({
    required this.label,
    required this.sectionColor,
    required this.onTap,
  });

  final String label;
  final Color sectionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: sectionColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        minTileHeight: 60,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sectionColor.withValues(alpha: 0.22)),
          ),
          child: Icon(Icons.add, color: sectionColor, size: 22),
        ),
        title: Text(
          label,
          style: theme.textStyles.title.copyWith(color: theme.colorScheme.onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
          size: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: sectionColor.withValues(alpha: 0.16)),
        ),
      ),
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

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        minTileHeight: 60,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 22),
        ),
        title: Text(
          account.name ?? _defaultName(account),
          style: theme.textStyles.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 132),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '\$$amountStr',
              maxLines: 1,
              style: theme.textStyles.titleSmallEmphasis.copyWith(
                color: isLiability ? AccountingColors.of(context).liability : null,
              ),
            ),
          ),
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
