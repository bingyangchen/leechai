import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HapticRefreshWrapper extends StatefulWidget {
  const HapticRefreshWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<HapticRefreshWrapper> createState() => _HapticRefreshWrapperState();
}

class _HapticRefreshWrapperState extends State<HapticRefreshWrapper> {
  double _dragOffset = 0;
  bool _triggered = false;
  bool _active = false;

  bool _atTop(ScrollMetrics m) {
    return (m.axisDirection == AxisDirection.down && m.extentBefore == 0) ||
        (m.axisDirection == AxisDirection.up && m.extentAfter == 0);
  }

  double _armedThreshold(double viewportDimension) {
    const kDragContainerExtentPercentage = 0.25;
    const kDragSizeFactorLimit = 1.5;
    return (viewportDimension * kDragContainerExtentPercentage) / kDragSizeFactorLimit;
  }

  bool _handleNotification(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _active = true;
      _dragOffset = 0;
      _triggered = false;
      return false;
    }
    if (n is ScrollEndNotification) {
      _active = false;
      _triggered = false;
      return false;
    }
    if (!_active || _triggered) return false;

    if (n is ScrollUpdateNotification && n.dragDetails != null) {
      if (!_atTop(n.metrics)) return false;
      if (n.metrics.axisDirection == AxisDirection.down) {
        _dragOffset -= n.scrollDelta ?? 0;
      } else if (n.metrics.axisDirection == AxisDirection.up) {
        _dragOffset += n.scrollDelta ?? 0;
      }
      _dragOffset = _dragOffset.clamp(0.0, double.infinity);
    } else if (n is OverscrollNotification) {
      if (!_atTop(n.metrics)) return false;
      if (n.metrics.axisDirection == AxisDirection.down) {
        _dragOffset -= n.overscroll;
      } else if (n.metrics.axisDirection == AxisDirection.up) {
        _dragOffset += n.overscroll;
      }
      _dragOffset = _dragOffset.clamp(0.0, double.infinity);
    }

    final threshold = _armedThreshold(n.metrics.viewportDimension);
    if (_dragOffset >= threshold) {
      _triggered = true;
      HapticFeedback.lightImpact();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleNotification,
      child: widget.child,
    );
  }
}
