import 'package:flutter/material.dart';
import 'package:mobile/core/constants/category_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
      primary: Colors.teal,
    ),
    extensions: [
      _AccountingColors(
        income: CategoryConstants.incomeColor,
        expense: CategoryConstants.expenseColor,
      ),
    ],
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
      primary: Colors.teal,
    ),
    extensions: [
      _AccountingColors(
        income: CategoryConstants.incomeColor,
        expense: CategoryConstants.expenseColor,
      ),
    ],
  );
}

class _AccountingColors extends ThemeExtension<_AccountingColors> {
  const _AccountingColors({required this.income, required this.expense});

  final Color income;
  final Color expense;

  @override
  _AccountingColors copyWith({Color? income, Color? expense}) =>
      _AccountingColors(
        income: income ?? this.income,
        expense: expense ?? this.expense,
      );

  @override
  _AccountingColors lerp(ThemeExtension<_AccountingColors>? other, double t) {
    if (other is! _AccountingColors) return this;
    return _AccountingColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
    );
  }
}
