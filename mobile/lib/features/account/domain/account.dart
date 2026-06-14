import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/domain/liability_type.dart';

enum AccountType { asset, liability, expense, income, equity }

class Account {
  const Account({
    required this.id,
    required this.type,
    required this.subType,
    this.name,
    this.icon,
    required this.initialBalance,
  });

  final String id;
  final AccountType type;
  final String subType;
  final String? name;
  final IconData? icon;
  final double initialBalance;

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    return AssetTypeX.fromName(subType)?.label ??
        LiabilityTypeX.fromName(subType)?.label ??
        subType;
  }

  bool get isPaymentMethod {
    switch (type) {
      case AccountType.asset:
        return AssetTypeX.fromName(subType)?.isPaymentMethod ?? false;
      case AccountType.liability:
        return LiabilityTypeX.fromName(subType)?.isPaymentMethod ?? false;
      case AccountType.expense:
      case AccountType.income:
      case AccountType.equity:
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
      case AccountType.equity:
        return Icons.balance;
    }
  }
}
