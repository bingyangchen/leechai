import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';

List<Account> filterAccountsForEntryType(
  List<Account> all, {
  required EntryType entryType,
  required bool isFrom,
}) {
  switch (entryType) {
    case EntryType.expense:
      return all.where((a) => a.isPaymentMethod).toList();
    case EntryType.income:
      return all.where((a) => a.type == AccountType.asset).toList();
    case EntryType.transfer:
      return all.where((a) => a.type == AccountType.asset).toList();
    case EntryType.borrow:
      if (isFrom) {
        return all.where((a) => a.type == AccountType.liability).toList();
      }
      return all.where((a) => a.type == AccountType.asset).toList();
    case EntryType.repay:
      if (isFrom) {
        return all.where((a) => a.type == AccountType.asset).toList();
      }
      return all.where((a) => a.type == AccountType.liability).toList();
  }
}
