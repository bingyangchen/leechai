import 'package:flutter/material.dart';

IconData? iconFromCodePoint(String? value) {
  if (value == null || value.isEmpty) return null;
  final codePoint = int.tryParse(value);
  if (codePoint == null) return null;
  return IconData(
    codePoint,
    fontFamily: Icons.restaurant.fontFamily,
    fontPackage: Icons.restaurant.fontPackage,
  );
}

String? iconToCodePoint(IconData? icon) {
  if (icon == null) return null;
  return icon.codePoint.toString();
}
