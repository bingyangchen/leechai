import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute('''
  CREATE TABLE IF NOT EXISTS account (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    sub_type TEXT NOT NULL,
    name TEXT NOT NULL,
    initial_balance REAL NOT NULL DEFAULT 0,
    last_used_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    created_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    deleted_at TEXT
  );
  ''');
  await seedDefaults(db);
}

Future<void> seedDefaults(Database db) async {
  await db.insert(
    'account',
    {'id': 'default_cash', 'type': 'asset', 'sub_type': 'cash', 'name': '現金'},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
  await db.insert(
    'account',
    {'id': 'default_bank', 'type': 'asset', 'sub_type': 'bank', 'name': '銀行'},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}
