import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute("""
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
  """);
  await db.execute('''
  CREATE INDEX IF NOT EXISTS entry_debit_account_occurred_at
  ON entry (debit_account_id, occurred_at DESC, created_at DESC);
  ''');
  await db.execute('''
  CREATE INDEX IF NOT EXISTS entry_credit_account_occurred_at
  ON entry (credit_account_id, occurred_at DESC, created_at DESC);
  ''');
}
