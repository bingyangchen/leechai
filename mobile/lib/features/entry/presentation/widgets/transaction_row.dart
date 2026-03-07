import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.entry,
    required this.accounts,
    required this.entryTagTitles,
    required this.privacyMode,
    required this.onTap,
    required this.onDelete,
    required this.onCopy,
    this.perspectiveAccountId,
  });

  final Map<String, Object?> entry;
  final Map<String, Account> accounts;
  final Map<String, List<String>> entryTagTitles;
  final bool privacyMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final String? perspectiveAccountId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appTextStyles = AppTextStyles.of(context);
    final typeStr = entry['type'] as String? ?? 'expense';
    final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
    final memo = entry['memo'] as String?;
    final debitId = entry['debit_account_id'] as String? ?? '';
    final creditId = entry['credit_account_id'] as String? ?? '';
    final debitAccount = accounts[debitId];
    final creditAccount = accounts[creditId];

    String title;
    if (memo != null && memo.trim().isNotEmpty) {
      final firstLine = memo.split('\n').first.trim();
      title = firstLine.length > 20 ? '${firstLine.substring(0, 20)}…' : firstLine;
    } else {
      title = _categoryLabel(type, debitAccount, creditAccount);
    }

    final accountLabel = _accountLabel(type, debitAccount, creditAccount);
    final entryId = entry['id'] as String? ?? '';
    final tagTitles = entryTagTitles[entryId] ?? [];

    final color = type == EntryType.adjustment && perspectiveAccountId != null
        ? EntryTypeColors.forAdjustment(
            context,
            isGain: perspectiveAccountId == debitId,
          )
        : EntryTypeColors.forType(context, type);
    final amountText = privacyMode
        ? '****'
        : (type == EntryType.income
              ? '+${formatAmountForDisplay(amount)}'
              : type == EntryType.expense
              ? '-${formatAmountForDisplay(amount)}'
              : type == EntryType.adjustment
              ? (_adjustmentAmountText(amount, debitId, creditId))
              : formatAmountForDisplay(amount));

    final showCopyAction = type != EntryType.adjustment;
    return Slidable(
      key: ValueKey(entry['id']),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            icon: Icons.delete_outline,
            label: '刪除',
          ),
        ],
      ),
      startActionPane: showCopyAction
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) => onCopy(),
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  icon: Icons.copy,
                  label: '複製',
                ),
              ],
            )
          : null,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _categoryIcon(type, debitAccount, creditAccount),
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: appTextStyles.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: (accountLabel != null || tagTitles.isNotEmpty)
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (accountLabel != null)
                      Text(
                        accountLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appTextStyles.bodySmallMuted,
                      ),
                    ...tagTitles.map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('#$t', style: appTextStyles.labelSmallMuted),
                      ),
                    ),
                  ],
                ),
              )
            : null,
        trailing: Text(
          amountText,
          style: appTextStyles.titleEmphasis.copyWith(color: color),
        ),
      ),
    );
  }

  String _adjustmentAmountText(double amount, String debitId, String creditId) {
    if (perspectiveAccountId == debitId) return '+${formatAmountForDisplay(amount)}';
    if (perspectiveAccountId == creditId) return '-${formatAmountForDisplay(amount)}';
    return formatAmountForDisplay(amount);
  }

  String _categoryLabel(EntryType type, Account? debit, Account? credit) {
    switch (type) {
      case EntryType.expense:
        return debit?.subType.isNotEmpty == true
            ? debit!.subType
            : (debit?.name ?? '支出');
      case EntryType.income:
        return credit?.subType.isNotEmpty == true
            ? credit!.subType
            : (credit?.name ?? '收入');
      case EntryType.adjustment:
        return type.label;
      default:
        return type.label;
    }
  }

  IconData _categoryIcon(EntryType type, Account? debit, Account? credit) {
    switch (type) {
      case EntryType.expense:
        return debit?.displayIcon ?? Icons.payments;
      case EntryType.income:
        return credit?.displayIcon ?? Icons.trending_up;
      case EntryType.transfer:
        return Icons.swap_horiz;
      case EntryType.borrow:
        return Icons.handshake;
      case EntryType.repay:
        return Icons.reply;
      case EntryType.adjustment:
        return Icons.show_chart;
    }
  }

  String? _accountLabel(EntryType type, Account? debit, Account? credit) {
    switch (type) {
      case EntryType.expense:
        return credit?.name ?? credit?.subType;
      case EntryType.income:
        return debit?.name ?? debit?.subType;
      case EntryType.transfer:
      case EntryType.borrow:
      case EntryType.repay:
        if (debit != null && credit != null) {
          return '${credit.name ?? credit.subType} → ${debit.name ?? debit.subType}';
        }
        return null;
      case EntryType.adjustment:
        return null;
    }
  }
}
