import 'package:flutter/material.dart';
import 'package:mobile/shared/constants/category.dart';

class _ShibaColors {
  _ShibaColors._();

  static const Color primaryLight = Color(0xFFC4956A);
  static const Color primaryDark = Color(0xFFE8C9A8);

  static const Color surfaceLight = Color(0xFFFDF8F3);
  static const Color surfaceContainerLight = Color(0xFFF5EDE4);

  static const Color surfaceDark = Color(0xFF2D2420);
  static const Color surfaceContainerDark = Color(0xFF3D322C);
  static const Color onSurfaceDark = Color(0xFFE8E0D8);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const primary = _ShibaColors.primaryLight;
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: const Color(0xFF3D2C29),
      primaryContainer: const Color(0xFFF5EDE4),
      onPrimaryContainer: const Color(0xFF2D2420),
      secondary: const Color(0xFFB8865B),
      onSecondary: Colors.white,
      surface: _ShibaColors.surfaceLight,
      onSurface: const Color(0xFF2D2420),
      surfaceContainerHighest: _ShibaColors.surfaceContainerLight,
      onSurfaceVariant: const Color(0xFF5C5048),
      outline: const Color(0xFF8B7D72),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      dividerColor: const Color(0xFFE8DED5),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: 36,
        titleTextStyle: TextStyle(fontSize: 16, color: colorScheme.onSurface),
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
    const primary = _ShibaColors.primaryDark;
    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: const Color(0xFF2D2420),
      primaryContainer: const Color(0xFF5C5048),
      onPrimaryContainer: _ShibaColors.primaryDark,
      secondary: const Color(0xFFE8C9A8),
      onSecondary: const Color(0xFF3D322C),
      surface: _ShibaColors.surfaceDark,
      onSurface: _ShibaColors.onSurfaceDark,
      surfaceContainerHighest: _ShibaColors.surfaceContainerDark,
      onSurfaceVariant: const Color(0xFFC8BDB2),
      outline: const Color(0xFF8B7D72),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      dividerColor: const Color(0xFF5C5048),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: 36,
        titleTextStyle: TextStyle(fontSize: 16, color: colorScheme.onSurface),
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
  _AccountingColors copyWith({Color? income, Color? expense}) => _AccountingColors(
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
