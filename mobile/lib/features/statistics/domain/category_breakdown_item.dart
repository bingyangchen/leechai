import 'package:flutter/material.dart';

class CategoryBreakdownItem {
  const CategoryBreakdownItem({
    required this.subType,
    required this.amount,
    required this.percent,
    required this.icon,
  });

  final String subType;
  final double amount;
  final double percent;
  final IconData icon;
}
