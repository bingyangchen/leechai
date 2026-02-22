import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute('''
  CREATE TABLE IF NOT EXISTS tag (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    updated_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    deleted_at TEXT,
    synced INTEGER NOT NULL DEFAULT 0
  );
  ''');
}
