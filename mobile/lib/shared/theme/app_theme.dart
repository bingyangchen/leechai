import 'package:flutter/material.dart';
import 'package:mobile/core/constants/category_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
      primary: Colors.teal,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      dividerColor: Colors.grey.shade200,
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: 36,
        titleTextStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
      extensions: [
        _AccountingColors(
          income: CategoryConstants.incomeColor,
          expense: CategoryConstants.expenseColor,
        ),
      ],
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
      primary: Colors.teal,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      dividerColor: Colors.grey.shade600,
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: 36,
        titleTextStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
      extensions: [
        _AccountingColors(
          income: CategoryConstants.incomeColor,
          expense: CategoryConstants.expenseColor,
        ),
      ],
    );
  }
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
