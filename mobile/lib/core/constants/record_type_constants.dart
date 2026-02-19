import 'package:flutter/material.dart';

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

class RecordTypeColors {
  RecordTypeColors._();

  static const Color expense = Color(0xFFE53935);
  static const Color income = Color(0xFF4CAF50);
  static const Color transfer = Color(0xFF2196F3);
  static const Color borrow = Color(0xFFFF9800);
  static const Color repay = Color(0xFF9C27B0);

  static Color forType(RecordType type) {
    switch (type) {
      case RecordType.expense:
        return expense;
      case RecordType.income:
        return income;
      case RecordType.transfer:
        return transfer;
      case RecordType.borrow:
        return borrow;
      case RecordType.repay:
        return repay;
    }
  }
}
