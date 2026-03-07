import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class NetWorthHeader extends StatelessWidget {
  const NetWorthHeader({
    super.key,
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.sparklinePoints,
    required this.privacyMode,
    required this.onPrivacyToggle,
  });

  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final List<double> sparklinePoints;
  final bool privacyMode;
  final VoidCallback onPrivacyToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTextStyles = AppTextStyles.of(context);
    final netStr = privacyMode ? '****' : formatAmountForDisplay(netWorth);
    final assetsStr = privacyMode ? '****' : formatAmountForDisplay(totalAssets);
    final liabStr = privacyMode ? '****' : formatAmountForDisplay(totalLiabilities);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('總淨資產', style: appTextStyles.sectionLabel),
              IconButton(
                onPressed: onPrivacyToggle,
                icon: Icon(
                  privacyMode
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 22,
                  color: colorScheme.onSurfaceVariant,
                ),
                tooltip: privacyMode ? '顯示金額' : '隱藏金額',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('\$$netStr', style: appTextStyles.headlineLargeEmphasis),
          const SizedBox(height: 8),
          Text(
            '總資產 \$$assetsStr - 總負債 \$$liabStr',
            style: appTextStyles.bodySmallMuted,
          ),
          if (sparklinePoints.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  points: sparklinePoints,
                  color: colorScheme.primary.withValues(alpha: 0.6),
                  fill: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points, required this.color, this.fill = false});

  final List<double> points;
  final Color color;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || points.length == 1) return;
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = (max - min).clamp(1.0, double.infinity);
    final w = size.width / (points.length - 1).clamp(1, points.length);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * w;
      final y = size.height - (points[i] - min) / range * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (fill) {
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points != points || old.color != color;
}
