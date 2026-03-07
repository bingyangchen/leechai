import 'package:flutter/widgets.dart';

Future<void> runRefreshWithSnapBack(
  ScrollController scrollController,
  Future<void> Function() onRefresh,
) async {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!scrollController.hasClients) return;
    try {
      (scrollController.position as dynamic).goBallistic(0.0);
    } catch (_) {}
  });
  await onRefresh();
}
