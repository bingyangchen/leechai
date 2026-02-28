import 'package:flutter/material.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class EntryTypeColors {
  EntryTypeColors._();

  static Color forType(BuildContext context, EntryType type) {
    final c = AccountingColors.of(context);
    switch (type) {
      case EntryType.expense:
        return c.expense;
      case EntryType.income:
        return c.income;
      case EntryType.transfer:
        return c.transfer;
      case EntryType.borrow:
        return c.borrow;
      case EntryType.repay:
        return c.repay;
    }
  }
}
