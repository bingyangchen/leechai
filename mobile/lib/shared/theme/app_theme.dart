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
  static const Color transfer = Color(0xFF2196F3);
  static const Color borrow = Color(0xFFFF9800);
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
      dividerColor: const Color(0xFFE8DED5),
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
      ],
    );
  }

  static const double _labelSize = 11;
  static const double _sectionLabelSize = 14;
  static const double _bodySmallSize = 12;
  static const double _bodySize = 14;
  static const double _bodyLargeSize = 16;
  static const double _titleSmallSize = 14;
  static const double _titleSize = 16;
  static const double _titleLargeSize = 22;
  static const double _headlineSize = 28;
  static const double _headlineLargeSize = 32;

  static AppTextStyles _appTextStyles(TextTheme textTheme, ColorScheme colorScheme) {
    const w400 = FontWeight.w400;
    const w500 = FontWeight.w500;
    const w600 = FontWeight.w600;
    const bold = FontWeight.bold;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
    final onSurface = colorScheme.onSurface;
    TextStyle merge(TextStyle? base, double size, FontWeight weight, Color color) =>
        (base ?? TextStyle()).copyWith(
          fontSize: size,
          fontWeight: weight,
          color: color,
        );
    TextStyle mergePreserveWeight(TextStyle? base, double size, Color color) =>
        (base ?? TextStyle()).copyWith(fontSize: size, color: color);
    return AppTextStyles(
      sectionLabel: merge(
        textTheme.titleSmall,
        _sectionLabelSize,
        w500,
        onSurfaceVariant,
      ),
      bodyMuted: merge(textTheme.bodyMedium, _bodySize, w400, onSurfaceVariant),
      bodyLargeMuted: merge(
        textTheme.bodyLarge,
        _bodyLargeSize,
        w400,
        onSurfaceVariant,
      ),
      bodyOnSurface: merge(textTheme.bodyMedium, _bodySize, w400, onSurface),
      bodySmallMuted: merge(
        textTheme.bodySmall,
        _bodySmallSize,
        w400,
        onSurfaceVariant,
      ),
      labelMuted: mergePreserveWeight(
        textTheme.labelSmall,
        _labelSize,
        onSurfaceVariant,
      ),
      titleMuted: merge(textTheme.titleMedium, _titleSize, w500, onSurfaceVariant),
      titleEmphasis: merge(textTheme.titleMedium, _titleSize, w600, onSurface),
      titleLargeEmphasis: merge(textTheme.titleLarge, _titleLargeSize, w600, onSurface),
      titleSmallEmphasis: merge(textTheme.titleSmall, _titleSmallSize, w600, onSurface),
      headlineEmphasis: merge(textTheme.headlineMedium, _headlineSize, bold, onSurface),
      headlineLargeEmphasis: merge(
        textTheme.headlineLarge,
        _headlineLargeSize,
        bold,
        onSurface,
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
      dividerColor: const Color(0xFF5C5048),
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
      ],
    );
  }
}

class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.sectionLabel,
    required this.bodyMuted,
    required this.bodyLargeMuted,
    required this.bodyOnSurface,
    required this.bodySmallMuted,
    required this.labelMuted,
    required this.titleMuted,
    required this.titleEmphasis,
    required this.titleLargeEmphasis,
    required this.titleSmallEmphasis,
    required this.headlineEmphasis,
    required this.headlineLargeEmphasis,
  });

  final TextStyle sectionLabel;
  final TextStyle bodyMuted;
  final TextStyle bodyLargeMuted;
  final TextStyle bodyOnSurface;
  final TextStyle bodySmallMuted;
  final TextStyle labelMuted;
  final TextStyle titleMuted;
  final TextStyle titleEmphasis;
  final TextStyle titleLargeEmphasis;
  final TextStyle titleSmallEmphasis;
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
    TextStyle? bodyMuted,
    TextStyle? bodyLargeMuted,
    TextStyle? bodyOnSurface,
    TextStyle? bodySmallMuted,
    TextStyle? labelMuted,
    TextStyle? titleMuted,
    TextStyle? titleEmphasis,
    TextStyle? titleLargeEmphasis,
    TextStyle? titleSmallEmphasis,
    TextStyle? headlineEmphasis,
    TextStyle? headlineLargeEmphasis,
  }) => AppTextStyles(
    sectionLabel: sectionLabel ?? this.sectionLabel,
    bodyMuted: bodyMuted ?? this.bodyMuted,
    bodyLargeMuted: bodyLargeMuted ?? this.bodyLargeMuted,
    bodyOnSurface: bodyOnSurface ?? this.bodyOnSurface,
    bodySmallMuted: bodySmallMuted ?? this.bodySmallMuted,
    labelMuted: labelMuted ?? this.labelMuted,
    titleMuted: titleMuted ?? this.titleMuted,
    titleEmphasis: titleEmphasis ?? this.titleEmphasis,
    titleLargeEmphasis: titleLargeEmphasis ?? this.titleLargeEmphasis,
    titleSmallEmphasis: titleSmallEmphasis ?? this.titleSmallEmphasis,
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
      bodyOnSurface: TextStyle.lerp(bodyOnSurface, other.bodyOnSurface, t)!,
      bodySmallMuted: TextStyle.lerp(bodySmallMuted, other.bodySmallMuted, t)!,
      labelMuted: TextStyle.lerp(labelMuted, other.labelMuted, t)!,
      titleMuted: TextStyle.lerp(titleMuted, other.titleMuted, t)!,
      titleEmphasis: TextStyle.lerp(titleEmphasis, other.titleEmphasis, t)!,
      titleLargeEmphasis: TextStyle.lerp(
        titleLargeEmphasis,
        other.titleLargeEmphasis,
        t,
      )!,
      titleSmallEmphasis: TextStyle.lerp(
        titleSmallEmphasis,
        other.titleSmallEmphasis,
        t,
      )!,
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
