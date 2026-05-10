import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/widgets/meta_chip.dart';

const double _accountRowHorizontalPadding = 24;
const double _accountRowArrowHorizontalPadding = 6;
const double _accountRowArrowIconSize = 20;
const double _accountChipTrailingIconSize = 18;
const double _accountChipTextLayoutSlack = 2;

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
      padding: const EdgeInsets.symmetric(horizontal: _accountRowHorizontalPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fromChipWidth = _estimateChipWidth(context, fromAccountLabel);
          final toChipWidth = _estimateChipWidth(context, toAccountLabel);
          const arrowWidth =
              _accountRowArrowIconSize + (_accountRowArrowHorizontalPadding * 2);
          final maxChipWidth = math.max(0.0, constraints.maxWidth - arrowWidth);
          final dualChipWidths = _dualChipWidths(
            maxChipWidth: maxChipWidth,
            fromChipWidth: fromChipWidth,
            toChipWidth: toChipWidth,
          );

          return Row(
            children: [
              if (isDual) ...[
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: dualChipWidths.from),
                  child: AccountChip(
                    account: fromAccount,
                    label: fromAccountLabel,
                    onTap: onAccountFromTap,
                    highlightConflict: highlightDualAccountConflict,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _accountRowArrowHorizontalPadding,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: _accountRowArrowIconSize,
                    color: highlightDualAccountConflict
                        ? colorScheme.error.withValues(alpha: 0.88)
                        : colorScheme.primary,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: dualChipWidths.to),
                  child: AccountChip(
                    account: toAccount,
                    label: toAccountLabel,
                    onTap: onAccountToTap,
                    highlightConflict: highlightDualAccountConflict,
                  ),
                ),
              ] else
                Flexible(
                  child: AccountChip(
                    account: singleAccount,
                    label: singleAccountLabel,
                    onTap: onAccountTap,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  ({double from, double to}) _dualChipWidths({
    required double maxChipWidth,
    required double fromChipWidth,
    required double toChipWidth,
  }) {
    if (fromChipWidth + toChipWidth <= maxChipWidth) {
      return (from: fromChipWidth, to: toChipWidth);
    }

    final halfWidth = maxChipWidth / 2;
    final fromWidth = fromChipWidth <= halfWidth
        ? fromChipWidth
        : maxChipWidth - toChipWidth.clamp(0.0, halfWidth).toDouble();
    final toWidth = toChipWidth <= halfWidth ? toChipWidth : maxChipWidth - fromWidth;

    return (from: fromWidth, to: toWidth);
  }

  double _estimateChipWidth(BuildContext context, String label) {
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: Theme.of(context).textStyles.body),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    return textPainter.maxIntrinsicWidth.ceilToDouble() +
        _accountChipTextLayoutSlack +
        (MetaChip.horizontalPadding * 2) +
        MetaChip.leadingIconSize +
        MetaChip.labelSpacing +
        MetaChip.trailingSpacing +
        _accountChipTrailingIconSize;
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
        size: _accountChipTrailingIconSize,
        color: highlightConflict
            ? colorScheme.error.withValues(alpha: 0.75)
            : colorScheme.onSurfaceVariant,
      ),
      truncateLabel: true,
    );
  }
}
