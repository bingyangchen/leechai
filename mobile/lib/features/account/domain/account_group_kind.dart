import 'package:flutter/material.dart';

enum AccountGroupKind { currentAssets, creditCard, investments, loans }

extension AccountGroupKindX on AccountGroupKind {
  String get title {
    switch (this) {
      case AccountGroupKind.currentAssets:
        return '流動資產';
      case AccountGroupKind.creditCard:
        return '信用卡';
      case AccountGroupKind.investments:
        return '投資';
      case AccountGroupKind.loans:
        return '貸款';
    }
  }

  IconData get sectionIcon {
    switch (this) {
      case AccountGroupKind.currentAssets:
        return Icons.account_balance_wallet;
      case AccountGroupKind.creditCard:
        return Icons.credit_card;
      case AccountGroupKind.investments:
        return Icons.show_chart;
      case AccountGroupKind.loans:
        return Icons.home;
    }
  }

  bool get isLiability =>
      this == AccountGroupKind.creditCard || this == AccountGroupKind.loans;

  String get addButtonLabel {
    switch (this) {
      case AccountGroupKind.currentAssets:
        return '新增帳戶...';
      case AccountGroupKind.creditCard:
        return '新增信用卡...';
      case AccountGroupKind.investments:
        return '新增投資帳戶...';
      case AccountGroupKind.loans:
        return '新增貸款帳戶...';
    }
  }
}
