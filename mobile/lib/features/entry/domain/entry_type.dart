enum EntryType {
  expense,
  income,
  transfer,
  borrow,
  repay,
}

extension EntryTypeX on EntryType {
  String get label {
    switch (this) {
      case EntryType.expense:
        return '支出';
      case EntryType.income:
        return '收入';
      case EntryType.transfer:
        return '轉帳';
      case EntryType.borrow:
        return '借入';
      case EntryType.repay:
        return '還款';
    }
  }

  bool get isDualAccount =>
      this == EntryType.transfer ||
      this == EntryType.borrow ||
      this == EntryType.repay;
}
