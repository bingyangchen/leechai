import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/features/profile/data/services/achievement.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/features/profile/presentation/widgets/achievement_notification_banner.dart';

class AchievementNotificationOverlay {
  AchievementNotificationOverlay._();

  static final AchievementNotificationOverlay instance =
      AchievementNotificationOverlay._();

  OverlayState? _overlayState;
  final List<AchievementItem> _queue = [];
  OverlayEntry? _currentEntry;
  StreamSubscription<AchievementItem>? _subscription;

  void attach(OverlayState overlayState) {
    if (_overlayState == overlayState) return;
    _subscription?.cancel();
    _overlayState = overlayState;
    for (final item in AchievementService.instance.drainPending()) {
      _onUnlocked(item);
    }
    _subscription = AchievementService.instance.onUnlocked.listen(_onUnlocked);
  }

  void _onUnlocked(AchievementItem item) {
    _queue.add(item);
    _processQueue();
  }

  void _processQueue() {
    if (_currentEntry != null || _queue.isEmpty || _overlayState == null) return;
    final item = _queue.removeAt(0);
    final entry = OverlayEntry(
      builder: (context) => AchievementNotificationBanner(
        item: item,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
          _processQueue();
        },
      ),
    );
    _currentEntry = entry;
    _overlayState!.insert(entry);
  }

  void detach() {
    _subscription?.cancel();
    _subscription = null;
    _overlayState = null;
    _currentEntry?.remove();
    _currentEntry = null;
    _queue.clear();
  }
}
