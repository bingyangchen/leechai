import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

Color colorForSubType(BuildContext context, String subType, int index) {
  final palette = ChartPalette.of(context).palette;
  final hash = subType.hashCode.abs();
  return palette[(hash + index) % palette.length];
}
