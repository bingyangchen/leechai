import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class NetWorthHeader extends StatelessWidget {
  const NetWorthHeader({
    super.key,
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.accountCount,
    required this.privacyMode,
    required this.onPrivacyToggle,
    this.collapseProgress = 0,
  });

  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final int accountCount;
  final bool privacyMode;
  final VoidCallback onPrivacyToggle;
  final double collapseProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final netWorthText = privacyMode ? '****' : formatAmountForDisplay(netWorth);
    final totalAssetsText = privacyMode ? '****' : formatAmountForDisplay(totalAssets);
    final totalLiabilitiesText = privacyMode
        ? '****'
        : formatAmountForDisplay(totalLiabilities);
    final clampedCollapseProgress = collapseProgress.clamp(0.0, 1.0);
    final detailOpacity = 1 - clampedCollapseProgress;
    final detailVisibilityScale = Curves.easeOut.transform(detailOpacity);
    final netWorthScale = lerpDouble(1.0, 0.84, clampedCollapseProgress)!;

    final headerTintColor = colorScheme.surface;
    final assetsValueColor = privacyMode
        ? colorScheme.onSurface
        : colorScheme.primary.withValues(alpha: 0.95);
    final liabilitiesValueColor = privacyMode
        ? colorScheme.onSurface
        : colorScheme.error.withValues(alpha: 0.92);

    return DecoratedBox(
      decoration: BoxDecoration(color: headerTintColor),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          20,
          lerpDouble(14, 10, clampedCollapseProgress)!,
          20,
          lerpDouble(26, 12, clampedCollapseProgress)!,
        ),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          border: Border(
            bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    size: 21,
                    color: privacyMode
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  tooltip: privacyMode ? '顯示金額' : '隱藏金額',
                ),
              ],
            ),
            SizedBox(height: lerpDouble(10, 0, clampedCollapseProgress)!),
            Transform.scale(
              alignment: Alignment.centerLeft,
              scale: netWorthScale,
              child: Text(
                '\$$netWorthText',
                style: theme.textStyles.headlineLargeEmphasis,
              ),
            ),
            SizedBox(height: lerpDouble(14, 0, clampedCollapseProgress)!),
            ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: detailVisibilityScale,
                child: Opacity(
                  opacity: detailOpacity,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('帳戶', style: theme.textStyles.bodySmallMuted),
                      Text('$accountCount', style: theme.textStyles.titleEmphasis),
                      Text(
                        '•',
                        style: theme.textStyles.bodySmallMuted.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      Text('總資產', style: theme.textStyles.bodySmallMuted),
                      Text(
                        '\$$totalAssetsText',
                        style: theme.textStyles.titleEmphasis.copyWith(
                          color: assetsValueColor,
                        ),
                      ),
                      Text(
                        '•',
                        style: theme.textStyles.bodySmallMuted.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      Text('總負債', style: theme.textStyles.bodySmallMuted),
                      Text(
                        '\$$totalLiabilitiesText',
                        style: theme.textStyles.titleEmphasis.copyWith(
                          color: liabilitiesValueColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
