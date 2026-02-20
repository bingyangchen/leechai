import 'package:flutter/material.dart';

/// Liability type, corresponds to the `liability.type` field in the DB schema.
/// Use [LiabilityType.name] when saving to database, and [LiabilityTypeX.fromName] for deserialization.
enum LiabilityType {
  creditCard,
  loan,
}

extension LiabilityTypeX on LiabilityType {
  String get label {
    switch (this) {
      case LiabilityType.creditCard:
        return '信用卡';
      case LiabilityType.loan:
        return '貸款';
    }
  }

  IconData get icon {
    switch (this) {
      case LiabilityType.creditCard:
        return Icons.credit_card;
      case LiabilityType.loan:
        return Icons.account_balance;
    }
  }

  static LiabilityType? fromName(String value) {
    for (final e in LiabilityType.values) {
      if (e.name == value) return e;
    }
    return null;
  }
}
