import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute('''
  CREATE TABLE IF NOT EXISTS account (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    sub_type TEXT NOT NULL,
    name TEXT NOT NULL,
    initial_balance REAL NOT NULL DEFAULT 0,
    is_payment_method INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    updated_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    deleted_at TEXT
  );
  ''');
}
