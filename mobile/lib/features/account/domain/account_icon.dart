import 'package:flutter/material.dart';

const List<IconData> _supportedAccountIcons = [
  Icons.wallet,
  Icons.account_balance,
  Icons.account_balance_wallet,
  Icons.credit_card,
  Icons.restaurant,
  Icons.directions_bus,
  Icons.home,
  Icons.movie,
  Icons.shopping_bag,
  Icons.more_horiz,
  Icons.payments,
  Icons.work,
  Icons.stars,
  Icons.trending_up,
  Icons.card_giftcard,
  Icons.balance,
  Icons.savings,
  Icons.show_chart,
  Icons.category,
];

final Map<String, IconData> _accountIconByCodePoint = {
  for (final icon in _supportedAccountIcons) icon.codePoint.toString(): icon,
};

IconData? iconFromCodePoint(String? value) {
  if (value == null || value.isEmpty) return null;
  return _accountIconByCodePoint[value];
}

String? iconToCodePoint(IconData? icon) {
  if (icon == null) return null;
  return icon.codePoint.toString();
}
