import 'package:mobile/core/database/app_database.dart';

class AchievementRepository {
  AchievementRepository._();

  static const String _table = 'achievements';

  static Future<List<Map<String, Object?>>> getAll() async {
    final db = await AppDatabase.database;
    return db.query(_table, orderBy: 'id ASC');
  }

  static Future<Map<String, Object?>?> getByAchievementId(String achievementId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [achievementId]);
    if (rows.isEmpty) return null;
    return rows.single;
  }

  static Future<void> updateProgress(
    String achievementId, {
    int? progress,
    DateTime? unlockedAt,
    int? completedCount,
    String? progressPeriod,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    final updates = <String, Object?>{'updated_at': now, 'synced': 0};
    if (progress != null) updates['progress'] = progress;
    if (completedCount != null) updates['completed_count'] = completedCount;
    if (progressPeriod != null) updates['progress_period'] = progressPeriod;
    await db.update(_table, updates, where: 'id = ?', whereArgs: [achievementId]);
    if (unlockedAt != null) {
      await db.rawUpdate(
        'UPDATE $_table SET unlocked_at = COALESCE(unlocked_at, ?), updated_at = ?, synced = 0 WHERE id = ?',
        [unlockedAt.toUtc().toIso8601String(), now, achievementId],
      );
    }
  }
}
