import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
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
  });

  final Map<String, Object?> entry;
  final Map<String, Account> accounts;
  final Map<String, List<String>> entryTagTitles;
  final bool privacyMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
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

    final color = EntryTypeColors.forType(context, type);
    final amountText = privacyMode
        ? '****'
        : (type == EntryType.income
              ? '+${formatAmountForDisplay(amount)}'
              : type == EntryType.expense
              ? '-${formatAmountForDisplay(amount)}'
              : formatAmountForDisplay(amount));

    return Slidable(
      key: ValueKey(entry['id']),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: '刪除',
          ),
        ],
      ),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onCopy(),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            icon: Icons.copy,
            label: '複製',
          ),
        ],
      ),
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
          style: const TextStyle(fontWeight: FontWeight.w500),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ...tagTitles.map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#$t',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
        trailing: Text(
          amountText,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: EntryTypeColors.forType(context, type),
          ),
        ),
      ),
    );
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
    }
  }
}
