import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class NetWorthHeader extends StatelessWidget {
  static const double _sparklineHeight = 52;

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
    final theme = Theme.of(context);
    final netStr = privacyMode ? '****' : formatAmountForDisplay(netWorth);
    final assetsStr = privacyMode ? '****' : formatAmountForDisplay(totalAssets);
    final liabStr = privacyMode ? '****' : formatAmountForDisplay(totalLiabilities);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.14)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('總淨資產', style: theme.textStyles.titleMuted),
              IconButton(
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  fixedSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onPrivacyToggle,
                icon: Icon(
                  privacyMode
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 22,
                  color: privacyMode
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: privacyMode ? '顯示金額' : '隱藏金額',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('\$$netStr', style: theme.textStyles.headlineLargeEmphasis),
          const SizedBox(height: 12),
          Text(
            '總資產 \$$assetsStr - 總負債 \$$liabStr',
            style: theme.textStyles.bodySmallMuted,
          ),
          if (sparklinePoints.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: _sparklineHeight,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  points: sparklinePoints,
                  color: theme.colorScheme.primary.withValues(alpha: 0.78),
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
    final step = size.width / (points.length - 1).clamp(1, points.length);
    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = i * step;
      final y = size.height - (points[i] - min) / range * (size.height - 4) - 2;
      offsets.add(Offset(x, y));
    }
    final strokePath = _smoothSparklinePath(offsets, size, closeToBottom: false);
    if (fill) {
      final fillPath = _smoothSparklinePath(offsets, size, closeToBottom: true);
      canvas.drawPath(
        fillPath,
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(
      strokePath,
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

Path _smoothSparklinePath(List<Offset> pts, Size size, {required bool closeToBottom}) {
  if (pts.length < 2) return Path();
  final path = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < pts.length - 1; i++) {
    final p0 = i == 0 ? pts[0] : pts[i - 1];
    final p1 = pts[i];
    final p2 = pts[i + 1];
    final p3 = i + 2 < pts.length ? pts[i + 2] : pts[i + 1];
    final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
    final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
    final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
    final cp2y = p2.dy - (p3.dy - p1.dy) / 6;
    path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
  }
  if (closeToBottom) {
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
  }
  return path;
}
