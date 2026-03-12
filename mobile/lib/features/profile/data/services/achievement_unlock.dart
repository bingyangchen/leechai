import 'dart:async';
import 'dart:developer' as developer;

import 'package:mobile/features/profile/data/repositories/achievement.dart';
import 'package:mobile/features/profile/domain/achievement_definitions.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyNotifiedIds = 'achievement_unlock_notified_ids';

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

  Future<void> clearNotifiedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNotifiedIds);
  }

  Future<void> checkAndNotify() async {
    try {
      final rows = await AchievementRepository.getAll();
      final achievements = achievementsFromRepositoryRows(rows, achievementDefinitions);
      final prefs = await SharedPreferences.getInstance();
      final notified = prefs.getStringList(_keyNotifiedIds) ?? [];
      final toNotify = achievements
          .where((a) => a.isUnlocked && !notified.contains(a.id))
          .toList();
      if (toNotify.isEmpty) return;
      final updated = [...notified];
      for (final item in toNotify) {
        _controller.add(item);
        _pendingUnlocks.add(item);
        updated.add(item.id);
      }
      await prefs.setStringList(_keyNotifiedIds, updated);
    } catch (error, stackTrace) {
      developer.log('checkAndNotify failed', error: error, stackTrace: stackTrace);
    }
  }

  void dispose() => _controller.close();
}
