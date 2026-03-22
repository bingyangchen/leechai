import 'package:flutter/material.dart';

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

class _AccountingColorValues {
  _AccountingColorValues._();

  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFE53935);
  static const Color transfer = Color(0xFF59A5D8);
  static const Color borrow = Color(0xFFF29555);
  static const Color repay = Color(0xFF9C27B0);
  static const Color liability = Color(0xFFE65100);
  static const Color neutral = Color(0xFF616161);
}

class _HeroCardContentValues {
  _HeroCardContentValues._();

  static const Color content = Color(0xFFFFFFFF);
  static const Color contentMuted = Color(0xE6FFFFFF);
  static final Color shadowSubtle = Colors.black.withValues(alpha: 0.08);
}

class _BarcodeColorValues {
  _BarcodeColorValues._();

  static const Color bar = Color(0xFF000000);
  static const Color background = Color(0xFFFFFFFF);
}

class _ChartPaletteValues {
  _ChartPaletteValues._();

  static const List<Color> light = [
    _ShibaColors.primaryLight,
    _AccountingColorValues.income,
    _AccountingColorValues.transfer,
    _AccountingColorValues.repay,
    _AccountingColorValues.borrow,
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF8BC34A),
    Color(0xFF673AB7),
    Color(0xFF009688),
    Color(0xFFCDDC39),
    Color(0xFF3F51B5),
  ];

  static const List<Color> dark = [
    _ShibaColors.primaryDark,
    _AccountingColorValues.income,
    _AccountingColorValues.transfer,
    _AccountingColorValues.repay,
    _AccountingColorValues.borrow,
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF8BC34A),
    Color(0xFF673AB7),
    Color(0xFF009688),
    Color(0xFFCDDC39),
    Color(0xFF3F51B5),
  ];
}

class AppTheme {
  AppTheme._();

  static const double topBarControlSlotHeight = 48;

  static TextTheme _textTheme(ColorScheme colorScheme, Brightness brightness) {
    final typography = Typography.material2021(colorScheme: colorScheme);
    return brightness == Brightness.light ? typography.black : typography.white;
  }

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
    final textTheme = _textTheme(colorScheme, Brightness.light);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      dividerColor: colorScheme.outline.withValues(alpha: 0.2),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: 36,
        titleTextStyle:
            textTheme.titleMedium?.copyWith(
              fontSize: 16,
              color: colorScheme.onSurface,
            ) ??
            TextStyle(fontSize: 16, color: colorScheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.surface,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        actionTextColor: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 2,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onSecondary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
      ),
      extensions: [
        _appTextStyles(textTheme, colorScheme),
        AccountingColors(
          income: _AccountingColorValues.income,
          expense: _AccountingColorValues.expense,
          transfer: _AccountingColorValues.transfer,
          borrow: _AccountingColorValues.borrow,
          repay: _AccountingColorValues.repay,
          liability: _AccountingColorValues.liability,
          neutral: _AccountingColorValues.neutral,
        ),
        ChartPalette(palette: _ChartPaletteValues.light),
        HeroCardColors(
          content: _HeroCardContentValues.content,
          contentMuted: _HeroCardContentValues.contentMuted,
          shadowSubtle: _HeroCardContentValues.shadowSubtle,
        ),
        BarcodeColors(
          bar: _BarcodeColorValues.bar,
          background: _BarcodeColorValues.background,
        ),
      ],
    );
  }

  static const double _labelSize = 12;
  static const double _labelSmallSize = 11;
  static const double _labelLargeSize = 14;
  static const double _bodySize = 14;
  static const double _bodySmallSize = 12;
  static const double _bodyLargeSize = 16;
  static const double _titleSize = 16;
  static const double _titleLargeSize = 22;
  static const double _titleSmallSize = 14;
  static const double _headlineSmallSize = 24;
  static const double _headlineSize = 28;
  static const double _headlineLargeSize = 32;

  static AppTextStyles _appTextStyles(TextTheme textTheme, ColorScheme colorScheme) {
    const w400 = FontWeight.w400;
    const w500 = FontWeight.w500;
    const w600 = FontWeight.w600;
    const bold = FontWeight.bold;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
    final onSurface = colorScheme.onSurface;

    TextStyle merge(
      TextStyle? base, {
      double? size,
      FontWeight? weight,
      Color? color,
    }) => (base ?? TextStyle()).copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );

    return AppTextStyles(
      sectionLabel: merge(
        textTheme.titleSmall,
        size: _labelLargeSize,
        weight: w500,
        color: onSurfaceVariant,
      ),
      labelSmallMuted: merge(
        textTheme.labelSmall,
        size: _labelSmallSize,
        color: onSurfaceVariant,
      ),
      labelMuted: merge(
        textTheme.labelMedium,
        size: _labelSize,
        color: onSurfaceVariant,
      ),
      labelEmphasis: merge(
        textTheme.labelMedium,
        size: _labelSize,
        weight: w600,
        color: onSurface,
      ),
      labelLarge: merge(
        textTheme.labelLarge,
        size: _labelLargeSize,
        weight: w400,
        color: onSurface,
      ),
      labelLargeEmphasis: merge(
        textTheme.labelLarge,
        size: _labelLargeSize,
        weight: w600,
        color: onSurface,
      ),
      body: merge(
        textTheme.bodyMedium,
        size: _bodySize,
        weight: w400,
        color: onSurface,
      ),
      bodyMuted: merge(
        textTheme.bodyMedium,
        size: _bodySize,
        weight: w400,
        color: onSurfaceVariant,
      ),
      bodySmallMuted: merge(
        textTheme.bodySmall,
        size: _bodySmallSize,
        color: onSurfaceVariant,
      ),
      bodyLargeMuted: merge(
        textTheme.bodyLarge,
        size: _bodyLargeSize,
        weight: w400,
        color: onSurfaceVariant,
      ),
      bodyLarge: merge(
        textTheme.bodyLarge,
        size: _bodyLargeSize,
        weight: w400,
        color: onSurface,
      ),
      title: merge(
        textTheme.titleMedium,
        size: _titleSize,
        weight: w500,
        color: onSurface,
      ),
      titleMuted: merge(
        textTheme.titleMedium,
        size: _titleSize,
        weight: w500,
        color: onSurfaceVariant,
      ),
      titleEmphasis: merge(
        textTheme.titleMedium,
        size: _titleSize,
        weight: w600,
        color: onSurface,
      ),
      titleLarge: merge(
        textTheme.titleLarge,
        size: _titleLargeSize,
        weight: w400,
        color: onSurface,
      ),
      titleLargeEmphasis: merge(
        textTheme.titleLarge,
        size: _titleLargeSize,
        weight: bold,
        color: onSurface,
      ),
      headlineSmall: merge(
        textTheme.headlineSmall,
        size: _headlineSmallSize,
        weight: w400,
        color: onSurface,
      ),
      headlineSmallEmphasis: merge(
        textTheme.headlineSmall,
        size: _headlineSmallSize,
        weight: bold,
        color: onSurface,
      ),
      titleSmallEmphasis: merge(
        textTheme.titleSmall,
        size: _titleSmallSize,
        weight: w600,
        color: onSurface,
      ),
      headline: merge(textTheme.headlineMedium, size: _headlineSize, color: onSurface),
      headlineEmphasis: merge(
        textTheme.headlineMedium,
        size: _headlineSize,
        weight: bold,
        color: onSurface,
      ),
      headlineLargeEmphasis: merge(
        textTheme.headlineLarge,
        size: _headlineLargeSize,
        weight: bold,
        color: onSurface,
      ),
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
    final textTheme = _textTheme(colorScheme, Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      dividerColor: colorScheme.onSurface.withValues(alpha: 0.2),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: 36,
        titleTextStyle:
            textTheme.titleMedium?.copyWith(
              fontSize: 16,
              color: colorScheme.onSurface,
            ) ??
            TextStyle(fontSize: 16, color: colorScheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.surface,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        actionTextColor: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 2,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onSecondary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
      ),
      extensions: [
        _appTextStyles(textTheme, colorScheme),
        AccountingColors(
          income: _AccountingColorValues.income,
          expense: _AccountingColorValues.expense,
          transfer: _AccountingColorValues.transfer,
          borrow: _AccountingColorValues.borrow,
          repay: _AccountingColorValues.repay,
          liability: _AccountingColorValues.liability,
          neutral: _AccountingColorValues.neutral,
        ),
        ChartPalette(palette: _ChartPaletteValues.dark),
        HeroCardColors(
          content: _HeroCardContentValues.content,
          contentMuted: _HeroCardContentValues.contentMuted,
          shadowSubtle: _HeroCardContentValues.shadowSubtle,
        ),
        BarcodeColors(
          bar: _BarcodeColorValues.bar,
          background: _BarcodeColorValues.background,
        ),
      ],
    );
  }
}

class BarcodeColors extends ThemeExtension<BarcodeColors> {
  const BarcodeColors({required this.bar, required this.background});

  final Color bar;
  final Color background;

  static BarcodeColors of(BuildContext context) {
    final ext = Theme.of(context).extension<BarcodeColors>();
    assert(ext != null);
    return ext!;
  }

  static BarcodeColors fromTheme(ThemeData theme) {
    final ext = theme.extension<BarcodeColors>();
    assert(ext != null);
    return ext!;
  }

  @override
  BarcodeColors copyWith({Color? bar, Color? background}) =>
      BarcodeColors(bar: bar ?? this.bar, background: background ?? this.background);

  @override
  BarcodeColors lerp(ThemeExtension<BarcodeColors>? other, double t) {
    if (other is! BarcodeColors) return this;
    return BarcodeColors(
      bar: Color.lerp(bar, other.bar, t)!,
      background: Color.lerp(background, other.background, t)!,
    );
  }
}

extension ThemeDataTextStyles on ThemeData {
  AppTextStyles get textStyles {
    final ext = extension<AppTextStyles>();
    assert(ext != null);
    return ext!;
  }
}

class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.sectionLabel,
    required this.bodyMuted,
    required this.bodyLargeMuted,
    required this.bodyLarge,
    required this.body,
    required this.bodySmallMuted,
    required this.labelSmallMuted,
    required this.labelMuted,
    required this.labelEmphasis,
    required this.labelLarge,
    required this.labelLargeEmphasis,
    required this.title,
    required this.titleMuted,
    required this.titleEmphasis,
    required this.titleLarge,
    required this.titleLargeEmphasis,
    required this.headlineSmall,
    required this.headlineSmallEmphasis,
    required this.titleSmallEmphasis,
    required this.headline,
    required this.headlineEmphasis,
    required this.headlineLargeEmphasis,
  });

  final TextStyle sectionLabel;
  final TextStyle labelMuted;
  final TextStyle labelSmallMuted;
  final TextStyle labelEmphasis;
  final TextStyle labelLarge;
  final TextStyle labelLargeEmphasis;
  final TextStyle body;
  final TextStyle bodyMuted;
  final TextStyle bodySmallMuted;
  final TextStyle bodyLargeMuted;
  final TextStyle bodyLarge;
  final TextStyle title;
  final TextStyle titleMuted;
  final TextStyle titleEmphasis;
  final TextStyle titleLarge;
  final TextStyle titleLargeEmphasis;
  final TextStyle headlineSmall;
  final TextStyle headlineSmallEmphasis;
  final TextStyle titleSmallEmphasis;
  final TextStyle headline;
  final TextStyle headlineEmphasis;
  final TextStyle headlineLargeEmphasis;

  static AppTextStyles of(BuildContext context) {
    final ext = Theme.of(context).extension<AppTextStyles>();
    assert(ext != null);
    return ext!;
  }

  @override
  AppTextStyles copyWith({
    TextStyle? sectionLabel,
    TextStyle? labelSmallMuted,
    TextStyle? labelMuted,
    TextStyle? labelEmphasis,
    TextStyle? labelLarge,
    TextStyle? labelLargeEmphasis,
    TextStyle? body,
    TextStyle? bodyMuted,
    TextStyle? bodyLargeMuted,
    TextStyle? bodyLarge,
    TextStyle? bodySmallMuted,
    TextStyle? title,
    TextStyle? titleMuted,
    TextStyle? titleEmphasis,
    TextStyle? titleLarge,
    TextStyle? titleLargeEmphasis,
    TextStyle? headlineSmall,
    TextStyle? headlineSmallEmphasis,
    TextStyle? titleSmallEmphasis,
    TextStyle? headline,
    TextStyle? headlineEmphasis,
    TextStyle? headlineLargeEmphasis,
  }) => AppTextStyles(
    sectionLabel: sectionLabel ?? this.sectionLabel,
    labelSmallMuted: labelSmallMuted ?? this.labelSmallMuted,
    labelMuted: labelMuted ?? this.labelMuted,
    labelEmphasis: labelEmphasis ?? this.labelEmphasis,
    labelLarge: labelLarge ?? this.labelLarge,
    labelLargeEmphasis: labelLargeEmphasis ?? this.labelLargeEmphasis,
    body: body ?? this.body,
    bodyMuted: bodyMuted ?? this.bodyMuted,
    bodyLargeMuted: bodyLargeMuted ?? this.bodyLargeMuted,
    bodyLarge: bodyLarge ?? this.bodyLarge,
    bodySmallMuted: bodySmallMuted ?? this.bodySmallMuted,
    title: title ?? this.title,
    titleMuted: titleMuted ?? this.titleMuted,
    titleEmphasis: titleEmphasis ?? this.titleEmphasis,
    titleLarge: titleLarge ?? this.titleLarge,
    titleLargeEmphasis: titleLargeEmphasis ?? this.titleLargeEmphasis,
    headlineSmall: headlineSmall ?? this.headlineSmall,
    headlineSmallEmphasis: headlineSmallEmphasis ?? this.headlineSmallEmphasis,
    titleSmallEmphasis: titleSmallEmphasis ?? this.titleSmallEmphasis,
    headline: headline ?? this.headline,
    headlineEmphasis: headlineEmphasis ?? this.headlineEmphasis,
    headlineLargeEmphasis: headlineLargeEmphasis ?? this.headlineLargeEmphasis,
  );

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    return AppTextStyles(
      sectionLabel: TextStyle.lerp(sectionLabel, other.sectionLabel, t)!,
      bodyMuted: TextStyle.lerp(bodyMuted, other.bodyMuted, t)!,
      bodyLargeMuted: TextStyle.lerp(bodyLargeMuted, other.bodyLargeMuted, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodySmallMuted: TextStyle.lerp(bodySmallMuted, other.bodySmallMuted, t)!,
      labelSmallMuted: TextStyle.lerp(labelSmallMuted, other.labelSmallMuted, t)!,
      labelMuted: TextStyle.lerp(labelMuted, other.labelMuted, t)!,
      labelEmphasis: TextStyle.lerp(labelEmphasis, other.labelEmphasis, t)!,
      labelLarge: TextStyle.lerp(labelLarge, other.labelLarge, t)!,
      labelLargeEmphasis: TextStyle.lerp(
        labelLargeEmphasis,
        other.labelLargeEmphasis,
        t,
      )!,
      title: TextStyle.lerp(title, other.title, t)!,
      titleMuted: TextStyle.lerp(titleMuted, other.titleMuted, t)!,
      titleEmphasis: TextStyle.lerp(titleEmphasis, other.titleEmphasis, t)!,
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t)!,
      titleLargeEmphasis: TextStyle.lerp(
        titleLargeEmphasis,
        other.titleLargeEmphasis,
        t,
      )!,
      headlineSmall: TextStyle.lerp(headlineSmall, other.headlineSmall, t)!,
      headlineSmallEmphasis: TextStyle.lerp(
        headlineSmallEmphasis,
        other.headlineSmallEmphasis,
        t,
      )!,
      titleSmallEmphasis: TextStyle.lerp(
        titleSmallEmphasis,
        other.titleSmallEmphasis,
        t,
      )!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      headlineEmphasis: TextStyle.lerp(headlineEmphasis, other.headlineEmphasis, t)!,
      headlineLargeEmphasis: TextStyle.lerp(
        headlineLargeEmphasis,
        other.headlineLargeEmphasis,
        t,
      )!,
    );
  }
}

class HeroCardColors extends ThemeExtension<HeroCardColors> {
  const HeroCardColors({
    required this.content,
    required this.contentMuted,
    required this.shadowSubtle,
  });

  final Color content;
  final Color contentMuted;
  final Color shadowSubtle;

  static HeroCardColors of(BuildContext context) {
    final ext = Theme.of(context).extension<HeroCardColors>();
    assert(ext != null);
    return ext!;
  }

  @override
  HeroCardColors copyWith({Color? content, Color? contentMuted, Color? shadowSubtle}) =>
      HeroCardColors(
        content: content ?? this.content,
        contentMuted: contentMuted ?? this.contentMuted,
        shadowSubtle: shadowSubtle ?? this.shadowSubtle,
      );

  @override
  HeroCardColors lerp(ThemeExtension<HeroCardColors>? other, double t) {
    if (other is! HeroCardColors) return this;
    return HeroCardColors(
      content: Color.lerp(content, other.content, t)!,
      contentMuted: Color.lerp(contentMuted, other.contentMuted, t)!,
      shadowSubtle: Color.lerp(shadowSubtle, other.shadowSubtle, t)!,
    );
  }
}

class ChartPalette extends ThemeExtension<ChartPalette> {
  const ChartPalette({required this.palette});

  final List<Color> palette;

  static ChartPalette of(BuildContext context) {
    final ext = Theme.of(context).extension<ChartPalette>();
    assert(ext != null);
    return ext!;
  }

  @override
  ChartPalette copyWith({List<Color>? palette}) =>
      ChartPalette(palette: palette ?? this.palette);

  @override
  ChartPalette lerp(ThemeExtension<ChartPalette>? other, double t) {
    if (other is! ChartPalette || palette.length != other.palette.length) {
      return this;
    }
    return ChartPalette(
      palette: [
        for (var i = 0; i < palette.length; i++)
          Color.lerp(palette[i], other.palette[i], t)!,
      ],
    );
  }
}

class AccountingColors extends ThemeExtension<AccountingColors> {
  const AccountingColors({
    required this.income,
    required this.expense,
    required this.transfer,
    required this.borrow,
    required this.repay,
    required this.liability,
    required this.neutral,
  });

  final Color income;
  final Color expense;
  final Color transfer;
  final Color borrow;
  final Color repay;
  final Color liability;
  final Color neutral;

  static AccountingColors of(BuildContext context) {
    final ext = Theme.of(context).extension<AccountingColors>();
    assert(ext != null);
    return ext!;
  }

  @override
  AccountingColors copyWith({
    Color? income,
    Color? expense,
    Color? transfer,
    Color? borrow,
    Color? repay,
    Color? liability,
    Color? neutral,
  }) => AccountingColors(
    income: income ?? this.income,
    expense: expense ?? this.expense,
    transfer: transfer ?? this.transfer,
    borrow: borrow ?? this.borrow,
    repay: repay ?? this.repay,
    liability: liability ?? this.liability,
    neutral: neutral ?? this.neutral,
  );

  @override
  AccountingColors lerp(ThemeExtension<AccountingColors>? other, double t) {
    if (other is! AccountingColors) return this;
    return AccountingColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      borrow: Color.lerp(borrow, other.borrow, t)!,
      repay: Color.lerp(repay, other.repay, t)!,
      liability: Color.lerp(liability, other.liability, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}
