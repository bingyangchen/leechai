import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mobile/core/database/schema.dart' as core_schema;
import 'package:mobile/features/account/data/schema/account.dart' as account_schema;
import 'package:mobile/features/budget/data/schema/budget.dart' as budget_schema;
import 'package:mobile/features/entry/data/schema/entry.dart' as entry_schema;
import 'package:mobile/features/entry/data/schema/entry_tag.dart' as entry_tag_schema;
import 'package:mobile/features/entry/data/schema/tag.dart' as tag_schema;
import 'package:mobile/features/profile/data/schema/achievement.dart'
    as achievement_schema;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static const String _dbName = 'leechai.db';
  static const int _dbVersion = 1;
  static Database? _db;
  static Future<Database>? _openFuture;

  static Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _openFuture ??= _open();
    _db = await _openFuture;
    return _db!;
  }

  static Future<Database> _open() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documentsDir.path, _dbName);

    // NOTE: This is only for development purposes.
    final file = File(dbPath);
    if (kDebugMode && file.existsSync()) file.deleteSync();

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await core_schema.run(db);
    await account_schema.run(db);
    await tag_schema.run(db);
    await entry_schema.run(db);
    await entry_tag_schema.run(db);
    await achievement_schema.run(db);
    await budget_schema.run(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // NOTE: handle schema migration
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _openFuture = null;
    }
  }
}
