import 'package:flutter/cupertino.dart';
import 'package:mobile/shared/constants/refresh_trigger.dart';

CupertinoSliverRefreshControl appSliverRefreshControl({RefreshCallback? onRefresh}) {
  return CupertinoSliverRefreshControl(
    refreshTriggerPullDistance: kRefreshTriggerPullDistance,
    refreshIndicatorExtent: kRefreshIndicatorExtent,
    builder: buildInstantDismissRefreshIndicator,
    onRefresh: onRefresh,
  );
}

Widget buildInstantDismissRefreshIndicator(
  BuildContext context,
  RefreshIndicatorMode refreshState,
  double pulledExtent,
  double refreshTriggerPullDistance,
  double refreshIndicatorExtent,
) {
  if (refreshState == RefreshIndicatorMode.done) {
    return const SizedBox.shrink();
  }
  return CupertinoSliverRefreshControl.buildRefreshIndicator(
    context,
    refreshState,
    pulledExtent,
    refreshTriggerPullDistance,
    refreshIndicatorExtent,
  );
}
