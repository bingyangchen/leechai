import 'package:flutter/cupertino.dart';
import 'package:mobile/shared/constants/refresh_trigger.dart';

CupertinoSliverRefreshControl appSliverRefreshControl({
  RefreshCallback? onRefresh,
  double statusBarOverlapInset = 0,
}) {
  if (statusBarOverlapInset <= 0) {
    return CupertinoSliverRefreshControl(
      refreshTriggerPullDistance: kRefreshTriggerPullDistance,
      refreshIndicatorExtent: kRefreshIndicatorExtent,
      builder: buildInstantDismissRefreshIndicator,
      onRefresh: onRefresh,
    );
  }
  return CupertinoSliverRefreshControl(
    refreshTriggerPullDistance: kRefreshTriggerPullDistance,
    refreshIndicatorExtent: kRefreshIndicatorExtent,
    builder: (context, refreshState, pulledExtent, triggerDist, indicatorExtent) {
      if (refreshState == RefreshIndicatorMode.done) {
        return const SizedBox.shrink();
      }
      return Transform.translate(
        offset: Offset(0, statusBarOverlapInset),
        child: CupertinoSliverRefreshControl.buildRefreshIndicator(
          context,
          refreshState,
          pulledExtent,
          triggerDist,
          indicatorExtent,
        ),
      );
    },
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
