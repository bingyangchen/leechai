import 'package:flutter/material.dart';

const List<IconData> _supportedAccountIcons = [
  Icons.wallet,
  Icons.account_balance,
  Icons.account_balance_wallet,
  Icons.credit_card,
  Icons.restaurant,
  Icons.directions_car,
  Icons.shopping_cart,
  Icons.home,
  Icons.movie,
  Icons.directions_bus,
  Icons.local_gas_station,
  Icons.flight,
  Icons.local_hospital,
  Icons.school,
  Icons.fitness_center,
  Icons.pets,
  Icons.card_giftcard,
  Icons.work,
  Icons.trending_up,
  Icons.savings,
  Icons.more_horiz,
  Icons.coffee,
  Icons.local_dining,
  Icons.shopping_bag,
  Icons.theater_comedy,
  Icons.music_note,
  Icons.book,
  Icons.phone_android,
  Icons.computer,
  Icons.electric_bolt,
  Icons.water_drop,
  Icons.cleaning_services,
  Icons.child_care,
  Icons.payments,
  Icons.star,
  Icons.stars,
  Icons.balance,
  Icons.show_chart,
  Icons.category,
  Icons.checkroom,
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
