import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

const int _paletteStride = 5;

Color colorForSubType(BuildContext context, String subType, int index) {
  final palette = ChartPalette.of(context).palette;
  final hash = subType.hashCode.abs();
  return palette[(hash + index) % palette.length];
}

Color colorForCategoryIndex(BuildContext context, int index) {
  final palette = ChartPalette.of(context).palette;
  final baseColor = palette[(index * _paletteStride) % palette.length];
  final cycle = index ~/ palette.length;
  if (cycle == 0) return baseColor;

  final hsl = HSLColor.fromColor(baseColor);
  final brightness = Theme.of(context).brightness;
  final hue = (hsl.hue + (cycle * 18)) % 360;
  final lightnessDelta = switch (cycle % 4) {
    1 => brightness == Brightness.dark ? 0.10 : -0.10,
    2 => brightness == Brightness.dark ? -0.08 : 0.08,
    3 => brightness == Brightness.dark ? 0.16 : -0.16,
    _ => brightness == Brightness.dark ? -0.14 : 0.14,
  };

  return hsl
      .withHue(hue)
      .withSaturation((hsl.saturation + 0.06).clamp(0.0, 1.0))
      .withLightness((hsl.lightness + lightnessDelta).clamp(0.24, 0.78))
      .toColor();
}
