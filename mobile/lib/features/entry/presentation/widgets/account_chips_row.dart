import 'package:flutter/material.dart';
import 'package:mobile/features/entry/domain/account_item.dart';
import 'package:mobile/features/entry/domain/record_type.dart';
import 'package:mobile/shared/widgets/meta_chip.dart';

class AccountChipsRow extends StatelessWidget {
  const AccountChipsRow({
    super.key,
    required this.recordType,
    this.singleAccount,
    required this.singleAccountLabel,
    this.fromAccount,
    this.toAccount,
    required this.fromAccountLabel,
    required this.toAccountLabel,
    required this.onAccountTap,
    required this.onAccountFromTap,
    required this.onAccountToTap,
  });

  final RecordType recordType;
  final AccountItem? singleAccount;
  final String singleAccountLabel;
  final AccountItem? fromAccount;
  final AccountItem? toAccount;
  final String fromAccountLabel;
  final String toAccountLabel;
  final VoidCallback onAccountTap;
  final VoidCallback onAccountFromTap;
  final VoidCallback onAccountToTap;

  @override
  Widget build(BuildContext context) {
    final isDual = recordType.isDualAccount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isDual) ...[
            AccountChip(
              account: fromAccount,
              label: fromAccountLabel,
              onTap: onAccountFromTap,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            AccountChip(
              account: toAccount,
              label: toAccountLabel,
              onTap: onAccountToTap,
            ),
          ] else
            AccountChip(
              account: singleAccount,
              label: singleAccountLabel,
              onTap: onAccountTap,
            ),
        ],
      ),
    );
  }
}

class AccountChip extends StatelessWidget {
  const AccountChip({
    super.key,
    this.account,
    required this.label,
    required this.onTap,
  });

  final AccountItem? account;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = account?.displayIcon ?? Icons.account_balance_wallet_outlined;

    return MetaChip(
      icon: icon,
      label: label,
      onTap: onTap,
      iconColor: theme.colorScheme.primary,
      trailing: Icon(
        Icons.keyboard_arrow_down,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
