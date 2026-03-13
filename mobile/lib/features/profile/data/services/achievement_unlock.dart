import 'dart:async';
import 'dart:developer' as developer;

import 'package:mobile/features/profile/data/repositories/achievement.dart';
import 'package:mobile/features/profile/domain/achievement_definitions.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';

class AchievementUnlockService {
  AchievementUnlockService._();

  static final AchievementUnlockService instance = AchievementUnlockService._();

  final _controller = StreamController<AchievementItem>.broadcast();
  Stream<AchievementItem> get onUnlocked => _controller.stream;

  final List<AchievementItem> _pendingUnlocks = [];

  List<AchievementItem> drainPending() {
    final list = _pendingUnlocks.toList();
    _pendingUnlocks.clear();
    return list;
  }

  Future<void> checkAndNotify() async {
    try {
      final rows = await AchievementRepository.getAll();
      final byId = {for (final r in rows) r['id'] as String: r};
      final achievements = achievementsFromRepositoryRows(rows, achievementDefinitions);
      final toNotify = achievements.where((a) {
        if (!a.isUnlocked) return false;
        final isNotified = (byId[a.id]?['is_notified'] as int?) ?? 0;
        return isNotified != 1;
      }).toList();
      if (toNotify.isEmpty) return;
      for (final item in toNotify) {
        _controller.add(item);
        _pendingUnlocks.add(item);
      }
      await AchievementRepository.markAsNotified(toNotify.map((a) => a.id).toList());
    } catch (error, stackTrace) {
      developer.log('checkAndNotify failed', error: error, stackTrace: stackTrace);
    }
  }

  void dispose() => _controller.close();
}
