import 'package:mobile/features/profile/domain/achievement_definitions.dart';

class AchievementItem {
  const AchievementItem({
    required this.id,
    required this.name,
    required this.description,
    required this.conditionText,
    required this.isUnlocked,
    this.unlockedAt,
    required this.current,
    required this.target,
    this.completedCount = 0,
    this.isSecret = false,
  });

  final String id;
  final String name;
  final String description;
  final String conditionText;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int current;
  final int target;
  final int completedCount;
  final bool isSecret;

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
}

class ProfilePageData {
  const ProfilePageData({
    required this.consecutiveActiveDays,
    required this.totalEntries,
    required this.totalDays,
    required this.entriesThisMonth,
    required this.noSpendDaysThisWeek,
    required this.achievements,
    this.totalBudgetSummary,
  });

  final int consecutiveActiveDays;
  final int totalEntries;
  final int totalDays;
  final int entriesThisMonth;
  final int noSpendDaysThisWeek;
  final List<AchievementItem> achievements;
  final double? totalBudgetSummary;

  int get unlockedBadgesCount =>
      achievements.where((achievement) => achievement.isUnlocked).length;
  int get totalBadgesCount => achievements.length;
}

List<AchievementItem> achievementsFromRepositoryRows(
  List<Map<String, Object?>> rows,
  List<AchievementDefinition> definitions,
) {
  final byId = {for (final r in rows) r['id'] as String: r};
  return definitions
      .where((def) {
        if (!def.isSecret) return true;
        final r = byId[def.id];
        return r != null && r['unlocked_at'] != null;
      })
      .map((def) {
        final r = byId[def.id];
        if (r == null) {
          return AchievementItem(
            id: def.id,
            name: def.name,
            description: def.description,
            conditionText: def.conditionText,
            isUnlocked: false,
            unlockedAt: null,
            current: 0,
            target: def.target,
            completedCount: 0,
            isSecret: def.isSecret,
          );
        }
        final unlockedAtStr = r['unlocked_at'] as String?;
        return AchievementItem(
          id: def.id,
          name: def.name,
          description: def.description,
          conditionText: def.conditionText,
          isUnlocked: unlockedAtStr != null,
          unlockedAt: unlockedAtStr != null ? DateTime.tryParse(unlockedAtStr) : null,
          current: (r['progress'] as int?) ?? 0,
          target: (r['target'] as int?) ?? def.target,
          completedCount: (r['completed_count'] as int?) ?? 0,
          isSecret: def.isSecret,
        );
      })
      .toList();
}
