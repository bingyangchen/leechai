enum RecordType {
  expense,
  income,
  transfer,
  borrow,
  repay,
}

extension RecordTypeX on RecordType {
  String get label {
    switch (this) {
      case RecordType.expense:
        return '支出';
      case RecordType.income:
        return '收入';
      case RecordType.transfer:
        return '轉帳';
      case RecordType.borrow:
        return '借入';
      case RecordType.repay:
        return '還款';
    }
  }

  bool get isDualAccount =>
      this == RecordType.transfer ||
      this == RecordType.borrow ||
      this == RecordType.repay;
}
