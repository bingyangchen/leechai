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
  });

  final String id;
  final String name;
  final String description;
  final String conditionText;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int current;
  final int target;

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
}

class ProfilePageData {
  const ProfilePageData({
    required this.weeklyStreak,
    required this.totalEntries,
    required this.totalDays,
    required this.entriesThisMonth,
    required this.noSpendDaysThisWeek,
    required this.achievements,
    this.totalBudgetSummary,
  });

  final int weeklyStreak;
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

List<AchievementItem> buildAchievements(int totalEntries) {
  // TODO: Design and implement
  final now = DateTime.now();
  final firstUnlocked = totalEntries >= 1;
  final hundredUnlocked = totalEntries >= 100;
  final threeWeeksUnlocked = false;

  return [
    AchievementItem(
      id: 'first_entry',
      name: '初來乍到',
      description: '完成你的第一筆記帳，開啟理財習慣養成之路。',
      conditionText: '記錄第一筆帳',
      isUnlocked: firstUnlocked,
      unlockedAt: firstUnlocked ? now.subtract(const Duration(days: 1)) : null,
      current: totalEntries.clamp(0, 1),
      target: 1,
    ),
    AchievementItem(
      id: 'hundred_entries',
      name: '百筆達成',
      description: '累積記帳滿 100 筆，你已經養成持續記錄的好習慣。',
      conditionText: '累積記帳 100 筆',
      isUnlocked: hundredUnlocked,
      unlockedAt: hundredUnlocked ? now.subtract(const Duration(days: 5)) : null,
      current: totalEntries.clamp(0, 100),
      target: 100,
    ),
    AchievementItem(
      id: 'three_weeks_streak',
      name: '理財日常',
      description: '連續 3 週都有記帳活動，代表你已把記帳融入生活。',
      conditionText: '連續 3 週有記帳',
      isUnlocked: threeWeeksUnlocked,
      unlockedAt: null,
      current: 0,
      target: 3,
    ),
  ];
}
