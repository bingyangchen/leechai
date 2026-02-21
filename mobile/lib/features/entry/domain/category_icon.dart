import 'package:flutter/material.dart';

IconData? categoryIcon(String? value) {
  if (value == null || value.isEmpty) return null;
  final codePoint = int.tryParse(value);
  if (codePoint == null) return null;
  return IconData(
    codePoint,
    fontFamily: Icons.restaurant.fontFamily,
    fontPackage: Icons.restaurant.fontPackage,
  );
}
