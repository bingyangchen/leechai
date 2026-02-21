import 'package:flutter/material.dart';

enum LiabilityType { creditCard, loan }

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

  bool get isPaymentMethod {
    switch (this) {
      case LiabilityType.creditCard:
        return true;
      case LiabilityType.loan:
        return false;
    }
  }

  static LiabilityType? fromName(String value) {
    for (final e in LiabilityType.values) {
      if (e.name == value) return e;
    }
    return null;
  }
}
