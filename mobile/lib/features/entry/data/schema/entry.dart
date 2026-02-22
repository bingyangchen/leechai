import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute('''
  CREATE TABLE IF NOT EXISTS entry (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    debit_account_id TEXT NOT NULL,
    credit_account_id TEXT NOT NULL,
    amount REAL NOT NULL,
    memo TEXT,
    occurred_at TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    updated_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    deleted_at TEXT,
    synced INTEGER NOT NULL DEFAULT 0
  );
  ''');
}
