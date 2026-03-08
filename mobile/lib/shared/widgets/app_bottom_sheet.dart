import 'package:flutter/material.dart';
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
        return DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          expand: false,
          builder: (_, scrollController) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DragHandle(),
                if (header case _?) header,
                Expanded(child: scrollableBuilder!(ctx, scrollController)),
              ],
            ),
          ),
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
