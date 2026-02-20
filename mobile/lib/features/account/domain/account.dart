import 'package:flutter/material.dart';

enum AccountType { asset, liability }

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.isPaymentMethod = false,
    this.icon,
  });

  final String id;
  final String name;
  final AccountType type;
  final bool isPaymentMethod;
  final IconData? icon;

  IconData get displayIcon {
    if (icon != null) return icon!;
    switch (type) {
      case AccountType.asset:
        return isPaymentMethod ? Icons.account_balance_wallet : Icons.savings;
      case AccountType.liability:
        return Icons.credit_card;
    }
  }
}
