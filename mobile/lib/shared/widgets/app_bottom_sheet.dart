import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:mobile/shared/theme/app_theme.dart';

enum AppBottomSheetMode { static, scrollable }

enum AppBottomSheetTitleAlignment { center, left }

typedef AppBottomSheetBuilder = Widget Function(BuildContext context);
typedef AppBottomSheetScrollableBuilder =
    Widget Function(BuildContext context, ScrollController scrollController);

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  String? title,
  bool showCloseButton = false,
  AppBottomSheetTitleAlignment titleAlignment = AppBottomSheetTitleAlignment.center,
  required AppBottomSheetMode mode,
  double initialChildSize = 0.5,
  double minChildSize = 0.3,
  double maxChildSize = 0.9,
  AppBottomSheetBuilder? builder,
  AppBottomSheetScrollableBuilder? scrollableBuilder,
}) {
  assert(
    mode == AppBottomSheetMode.static && builder != null ||
        mode == AppBottomSheetMode.scrollable && scrollableBuilder != null,
    'Static mode requires builder; scrollable mode requires scrollableBuilder.',
  );
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final showHeader = title != null || showCloseButton;
      final header = showHeader
          ? _AppBottomSheetHeader(
              title: title,
              showCloseButton: showCloseButton,
              titleAlignment: titleAlignment,
              onClose: () => Navigator.of(ctx).pop(),
            )
          : null;

      if (mode == AppBottomSheetMode.scrollable) {
        return _ScrollableSheetWithResize(
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          header: header,
          scrollableBuilder: scrollableBuilder!,
          sheetContext: ctx,
        );
      }
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            if (header case _?) header,
            Flexible(child: builder!(ctx)),
          ],
        ),
      );
    },
  );
}

class _ScrollableSheetWithResize extends StatefulWidget {
  const _ScrollableSheetWithResize({
    required this.initialChildSize,
    required this.minChildSize,
    required this.maxChildSize,
    required this.header,
    required this.scrollableBuilder,
    required this.sheetContext,
  });

  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final Widget? header;
  final AppBottomSheetScrollableBuilder scrollableBuilder;
  final BuildContext sheetContext;

  @override
  State<_ScrollableSheetWithResize> createState() => _ScrollableSheetWithResizeState();
}

class _ScrollableSheetWithResizeState extends State<_ScrollableSheetWithResize>
    with SingleTickerProviderStateMixin {
  late final DraggableScrollableController _controller;
  late final ValueNotifier<double> _currentSize;
  late final AnimationController _flingAnimation;
  bool _hasExpandedForKeyboard = false;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
    _currentSize = ValueNotifier(widget.initialChildSize);
    _flingAnimation = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _flingAnimation.dispose();
    _controller.dispose();
    _currentSize.dispose();
    super.dispose();
  }

  void _onHandleFling(double velocityPixelsPerSecond) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sizeVelocity = -velocityPixelsPerSecond / screenHeight;
    const drag = 0.0001;
    final simulation = FrictionSimulation(drag, _currentSize.value, sizeVelocity);
    void listener() {
      if (!_controller.isAttached) return;
      _controller.jumpTo(
        _flingAnimation.value.clamp(widget.minChildSize, widget.maxChildSize),
      );
    }

    _flingAnimation.addListener(listener);
    _flingAnimation.animateWith(simulation).whenComplete(() {
      _flingAnimation.removeListener(listener);
    });
  }

  static const int _maxKeyboardExpandFrames = 20;

  void _scheduleJumpToMaxForKeyboard({int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.isAttached) {
        _controller.jumpTo(widget.maxChildSize);
        return;
      }
      if (attempt >= _maxKeyboardExpandFrames) return;
      _scheduleJumpToMaxForKeyboard(attempt: attempt + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    if (viewInsetsBottom > 0 && !_hasExpandedForKeyboard) {
      _hasExpandedForKeyboard = true;
      _scheduleJumpToMaxForKeyboard();
    } else if (viewInsetsBottom == 0) {
      _hasExpandedForKeyboard = false;
    }
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: widget.initialChildSize,
      minChildSize: widget.minChildSize,
      maxChildSize: widget.maxChildSize,
      expand: false,
      builder: (_, scrollController) =>
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _currentSize.value = notification.extent;
              return false;
            },
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DragHandle(
                    resizeController: _controller,
                    currentSize: _currentSize,
                    minChildSize: widget.minChildSize,
                    maxChildSize: widget.maxChildSize,
                    onFling: _onHandleFling,
                  ),
                  if (widget.header case _?) widget.header!,
                  Expanded(
                    child: widget.scrollableBuilder(
                      widget.sheetContext,
                      scrollController,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({
    this.resizeController,
    this.currentSize,
    this.minChildSize,
    this.maxChildSize,
    this.onFling,
  });

  final DraggableScrollableController? resizeController;
  final ValueNotifier<double>? currentSize;
  final double? minChildSize;
  final double? maxChildSize;
  final void Function(double velocityPixelsPerSecond)? onFling;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );

    if (resizeController != null &&
        currentSize != null &&
        minChildSize != null &&
        maxChildSize != null) {
      final controller = resizeController!;
      final sizeNotifier = currentSize!;
      final min = minChildSize!;
      final max = maxChildSize!;
      final screenHeight = MediaQuery.sizeOf(context).height;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) {
          final deltaFraction = -details.delta.dy / screenHeight;
          final next = (sizeNotifier.value + deltaFraction).clamp(min, max);
          controller.jumpTo(next);
        },
        onVerticalDragEnd: onFling != null
            ? (details) => onFling!(details.velocity.pixelsPerSecond.dy)
            : null,
        child: content,
      );
    }

    return content;
  }
}

class _AppBottomSheetHeader extends StatelessWidget {
  const _AppBottomSheetHeader({
    this.title,
    required this.showCloseButton,
    required this.titleAlignment,
    required this.onClose,
  });

  final String? title;
  final bool showCloseButton;
  final AppBottomSheetTitleAlignment titleAlignment;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (title != null)
            Expanded(
              child: Align(
                alignment: titleAlignment == AppBottomSheetTitleAlignment.center
                    ? Alignment.center
                    : Alignment.centerLeft,
                child: Text(title!, style: theme.textStyles.headlineSmall),
              ),
            )
          else
            const Spacer(),
          if (showCloseButton)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
        ],
      ),
    );
  }
}
