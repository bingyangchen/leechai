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
    required this.onTotalAssetsTap,
    required this.onTotalLiabilitiesTap,
    this.collapseProgress = 0,
  });

  final double netWorth;
  final double totalAssets;
  final double totalLiabilities;
  final int accountCount;
  final bool privacyMode;
  final VoidCallback onPrivacyToggle;
  final VoidCallback onTotalAssetsTap;
  final VoidCallback onTotalLiabilitiesTap;
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
            Transform.translate(
              offset: Offset(0, lerpDouble(0, -8, clampedCollapseProgress)!),
              child: Transform.scale(
                alignment: Alignment.centerLeft,
                scale: netWorthScale,
                child: Text(
                  '\$$netWorthText',
                  style: theme.textStyles.headlineLargeEmphasis,
                ),
              ),
            ),
            SizedBox(height: lerpDouble(14, 0, clampedCollapseProgress)!),
            ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: detailVisibilityScale,
                child: Opacity(
                  opacity: detailOpacity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AccountCountMetric(accountCount: accountCount),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _HeaderAmountMetric(
                              label: '總資產',
                              amountText: totalAssetsText,
                              valueColor: assetsValueColor,
                              semanticLabel: '查看總資產組成',
                              onTap: onTotalAssetsTap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HeaderAmountMetric(
                              label: '總負債',
                              amountText: totalLiabilitiesText,
                              valueColor: liabilitiesValueColor,
                              semanticLabel: '查看總負債組成',
                              onTap: onTotalLiabilitiesTap,
                            ),
                          ),
                        ],
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

class _AccountCountMetric extends StatelessWidget {
  const _AccountCountMetric({required this.accountCount});

  final int accountCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('帳戶', style: theme.textStyles.bodySmallMuted),
            const SizedBox(width: 6),
            Text('$accountCount', style: theme.textStyles.titleEmphasis),
          ],
        ),
      ),
    );
  }
}

class _HeaderAmountMetric extends StatelessWidget {
  const _HeaderAmountMetric({
    required this.label,
    required this.amountText,
    required this.valueColor,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String amountText;
  final Color valueColor;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textStyles.bodySmallMuted),
                      const SizedBox(height: 2),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 132),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '\$$amountText',
                            maxLines: 1,
                            style: theme.textStyles.titleEmphasis.copyWith(
                              color: valueColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
