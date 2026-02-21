import 'package:flutter/material.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';

class EntryTypeColors {
  EntryTypeColors._();

  static const Color expense = Color(0xFFE53935);
  static const Color income = Color(0xFF4CAF50);
  static const Color transfer = Color(0xFF2196F3);
  static const Color borrow = Color(0xFFFF9800);
  static const Color repay = Color(0xFF9C27B0);

  static Color forType(EntryType type) {
    switch (type) {
      case EntryType.expense:
        return expense;
      case EntryType.income:
        return income;
      case EntryType.transfer:
        return transfer;
      case EntryType.borrow:
        return borrow;
      case EntryType.repay:
        return repay;
    }
  }
}
