import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/shared/widgets/meta_chip.dart';

class AccountChipsRow extends StatelessWidget {
  const AccountChipsRow({
    super.key,
    required this.entryType,
    this.singleAccount,
    required this.singleAccountLabel,
    this.fromAccount,
    this.toAccount,
    required this.fromAccountLabel,
    required this.toAccountLabel,
    required this.onAccountTap,
    required this.onAccountFromTap,
    required this.onAccountToTap,
    this.highlightDualAccountConflict = false,
  });

  final EntryType entryType;
  final Account? singleAccount;
  final String singleAccountLabel;
  final Account? fromAccount;
  final Account? toAccount;
  final String fromAccountLabel;
  final String toAccountLabel;
  final VoidCallback onAccountTap;
  final VoidCallback onAccountFromTap;
  final VoidCallback onAccountToTap;
  final bool highlightDualAccountConflict;

  @override
  Widget build(BuildContext context) {
    final isDual = entryType.isDualAccount;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isDual) ...[
            AccountChip(
              account: fromAccount,
              label: fromAccountLabel,
              onTap: onAccountFromTap,
              highlightConflict: highlightDualAccountConflict,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward,
                size: 20,
                color: highlightDualAccountConflict
                    ? colorScheme.error.withValues(alpha: 0.88)
                    : colorScheme.primary,
              ),
            ),
            AccountChip(
              account: toAccount,
              label: toAccountLabel,
              onTap: onAccountToTap,
              highlightConflict: highlightDualAccountConflict,
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
    this.highlightConflict = false,
  });

  final Account? account;
  final String label;
  final VoidCallback onTap;
  final bool highlightConflict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final icon = account?.displayIcon ?? Icons.account_balance_wallet_outlined;
    final errorWashAlpha = theme.brightness == Brightness.light ? 0.16 : 0.22;

    return MetaChip(
      icon: icon,
      label: label,
      onTap: onTap,
      iconColor: highlightConflict ? colorScheme.error : colorScheme.primary,
      backgroundColor: highlightConflict
          ? Color.alphaBlend(
              colorScheme.error.withValues(alpha: errorWashAlpha),
              colorScheme.surfaceContainerHighest,
            )
          : null,
      trailing: Icon(
        Icons.keyboard_arrow_down,
        size: 18,
        color: highlightConflict
            ? colorScheme.error.withValues(alpha: 0.75)
            : colorScheme.onSurfaceVariant,
      ),
    );
  }
}
