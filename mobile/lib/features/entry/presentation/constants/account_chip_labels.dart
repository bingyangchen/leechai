import 'package:mobile/features/entry/domain/entry_type.dart';

String accountChipLabel(EntryType entryType, {required bool isFrom}) {
  switch (entryType) {
    case EntryType.expense:
      return '支付工具';
    case EntryType.income:
      return '存入帳戶';
    case EntryType.transfer:
      return isFrom ? '轉出' : '轉入';
    case EntryType.borrow:
      return isFrom ? '債權人' : '存入';
    case EntryType.repay:
      return isFrom ? '付款源' : '還債';
    case EntryType.adjustment:
      return '';
  }
}
