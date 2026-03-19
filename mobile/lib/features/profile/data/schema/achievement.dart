import 'package:mobile/features/profile/domain/achievement_definitions.dart';
import 'package:sqflite/sqflite.dart';

const _table = 'achievement';

Future<void> run(Database db) async {
  await db.execute("""
  CREATE TABLE IF NOT EXISTS $_table (
    id TEXT PRIMARY KEY,
    progress INTEGER NOT NULL DEFAULT 0,
    target INTEGER NOT NULL,
    unlocked_at TEXT,
    completed_count INTEGER NOT NULL DEFAULT 0,
    progress_period TEXT,
    is_notified INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    updated_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    synced INTEGER NOT NULL DEFAULT 0
  );
  """);
  await seedDefaults(db);
}

Future<void> seedDefaults(Database db) async {
  final now = DateTime.now().toUtc().toIso8601String();
  for (final def in achievementDefinitions) {
    await db.insert(_table, {
      'id': def.achievementId.key,
      'target': def.target,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
