import 'package:flutter/widgets.dart';

class DataRefreshScope extends InheritedWidget {
  const DataRefreshScope({
    super.key,
    required this.triggerRefresh,
    required super.child,
  });

  final VoidCallback triggerRefresh;

  static DataRefreshScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DataRefreshScope>();
  }

  static void notify(BuildContext context) {
    maybeOf(context)?.triggerRefresh();
  }

  @override
  bool updateShouldNotify(DataRefreshScope oldWidget) =>
      triggerRefresh != oldWidget.triggerRefresh;
}
