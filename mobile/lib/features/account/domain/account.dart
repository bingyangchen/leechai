import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/domain/liability_type.dart';

enum AccountType { asset, liability, expense, income }

class Account {
  const Account({
    required this.id,
    required this.type,
    required this.subType,
    this.name,
    this.icon,
  });

  final String id;
  final AccountType type;
  final String subType;
  final String? name;
  final IconData? icon;

  bool get isPaymentMethod {
    switch (type) {
      case AccountType.asset:
        return AssetTypeX.fromName(subType)?.isPaymentMethod ?? false;
      case AccountType.liability:
        return LiabilityTypeX.fromName(subType)?.isPaymentMethod ?? false;
      case AccountType.expense:
      case AccountType.income:
        return false;
    }
  }

  IconData get displayIcon {
    if (icon != null) return icon!;
    switch (type) {
      case AccountType.asset:
        return isPaymentMethod ? Icons.account_balance_wallet : Icons.savings;
      case AccountType.liability:
        return Icons.credit_card;
      case AccountType.expense:
        return Icons.payments;
      case AccountType.income:
        return Icons.trending_up;
    }
  }
}
