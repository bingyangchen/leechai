import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

const double kSlidingSegmentTrackPadding = 5;
const double kSlidingSegmentTrackRadius = 12;
const double kSlidingSegmentThumbMargin = 4;
const double kSlidingSegmentThumbRadius = 8;
const double kSlidingSegmentLabelVerticalPadding = 12;

class SlidingSegmentedControl extends StatelessWidget {
  const SlidingSegmentedControl({
    super.key,
    required this.segmentLabels,
    required this.selectedIndex,
    required this.onSelected,
    required this.thumbDecoration,
    required this.selectedLabelColor,
    this.labelVerticalPadding = kSlidingSegmentLabelVerticalPadding,
    this.labelStyle,
  });

  final List<String> segmentLabels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final BoxDecoration thumbDecoration;
  final Color Function(int index) selectedLabelColor;
  final double labelVerticalPadding;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = segmentLabels.length;
    assert(count >= 2, 'SlidingSegmentedControl expects at least two segments.');

    return Container(
      padding: const EdgeInsets.all(kSlidingSegmentTrackPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(kSlidingSegmentTrackRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final margin = kSlidingSegmentThumbMargin;
          final segmentWidth = constraints.maxWidth / count;
          final safeIndex = selectedIndex.clamp(0, count - 1);
          final indicatorLeft = margin + safeIndex * segmentWidth;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: indicatorLeft,
                top: margin,
                bottom: margin,
                width: segmentWidth - margin * 2,
                child: DecoratedBox(decoration: thumbDecoration),
              ),
              Row(
                children: List.generate(count, (index) {
                  final selected = index == safeIndex;
                  return Expanded(
                    child: _SegmentCell(
                      label: segmentLabels[index],
                      selected: selected,
                      selectedColor: selectedLabelColor(index),
                      labelVerticalPadding: labelVerticalPadding,
                      labelStyle: labelStyle,
                      onTap: () => onSelected(index),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentCell extends StatefulWidget {
  const _SegmentCell({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.labelVerticalPadding,
    required this.labelStyle,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final double labelVerticalPadding;
  final TextStyle? labelStyle;
  final VoidCallback onTap;

  @override
  State<_SegmentCell> createState() => _SegmentCellState();
}

class _SegmentCellState extends State<_SegmentCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.selected
        ? widget.selectedColor
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.labelVerticalPadding),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: (widget.labelStyle ?? theme.textStyles.sectionLabel).copyWith(
              color: color,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(widget.label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

BoxDecoration slidingSegmentElevatedThumb(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: scheme.surface,
    borderRadius: BorderRadius.circular(kSlidingSegmentThumbRadius),
    boxShadow: [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: 0.06),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ],
  );
}

BoxDecoration slidingSegmentPrimaryThumb(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.primaryContainer,
    borderRadius: BorderRadius.circular(kSlidingSegmentThumbRadius),
  );
}
