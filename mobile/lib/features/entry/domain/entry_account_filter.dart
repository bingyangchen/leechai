import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';

List<Account> filterAccountsForEntryType(
  List<Account> all, {
  required EntryType entryType,
  required bool isFrom,
}) {
  final balanceAccounts = all
      .where((a) => a.type == AccountType.asset || a.type == AccountType.liability)
      .toList();

  switch (entryType) {
    case EntryType.expense:
      return balanceAccounts.where((a) => a.isPaymentMethod).toList();
    case EntryType.income:
      return balanceAccounts
          .where((a) => a.type == AccountType.asset && a.isPaymentMethod)
          .toList();
    case EntryType.transfer:
      return balanceAccounts.where((a) => a.type == AccountType.asset).toList();
    case EntryType.borrow:
      if (isFrom) {
        return balanceAccounts.where((a) => a.type == AccountType.liability).toList();
      }
      return balanceAccounts.where((a) => a.type == AccountType.asset).toList();
    case EntryType.repay:
      if (isFrom) {
        return balanceAccounts
            .where((a) => a.type == AccountType.asset && a.isPaymentMethod)
            .toList();
      }
      return balanceAccounts.where((a) => a.type == AccountType.liability).toList();
    case EntryType.adjustment:
      return [];
  }
}
