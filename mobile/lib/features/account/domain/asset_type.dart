import 'package:flutter/material.dart';

/// Asset type, corresponds to the `asset.type` field in the DB schema.
/// Use [AssetType.name] when saving to database, and [AssetTypeX.fromName] for deserialization.
enum AssetType {
  bank,
  cash,
  epayment,
  securities,
  storedValueCard,
  other,
}

extension AssetTypeX on AssetType {
  String get label {
    switch (this) {
      case AssetType.bank:
        return '銀行';
      case AssetType.cash:
        return '現金';
      case AssetType.epayment:
        return '電子支付';
      case AssetType.securities:
        return '證券';
      case AssetType.storedValueCard:
        return '儲值卡';
      case AssetType.other:
        return '其他';
    }
  }

  IconData get icon {
    switch (this) {
      case AssetType.bank:
        return Icons.account_balance;
      case AssetType.cash:
        return Icons.account_balance_wallet;
      case AssetType.epayment:
        return Icons.account_balance_wallet;
      case AssetType.securities:
        return Icons.show_chart;
      case AssetType.storedValueCard:
        return Icons.credit_card;
      case AssetType.other:
        return Icons.category;
    }
  }

  bool get isPaymentMethod {
    switch (this) {
      case AssetType.cash:
      case AssetType.epayment:
      case AssetType.storedValueCard:
        return true;
      case AssetType.bank:
      case AssetType.securities:
      case AssetType.other:
        return false;
    }
  }

  static AssetType? fromName(String value) {
    for (final e in AssetType.values) {
      if (e.name == value) return e;
    }
    return null;
  }
}
