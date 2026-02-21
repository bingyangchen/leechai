import 'dart:convert';

import 'package:mobile/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class EntryRepository {
  EntryRepository._();

  static const String _table = 'entry';
  static final _uuid = Uuid();

  static Future<List<Map<String, Object?>>> getAll() async {
    final db = await AppDatabase.database;
    return db.query(_table, where: 'deleted_at IS NULL', orderBy: 'occurred_at DESC');
  }

  static Future<void> insert({
    required String type,
    required String debitAccountId,
    required String creditAccountId,
    required double amount,
    required List<String> tagIds,
    String? memo,
    required DateTime occurredAt,
  }) async {
    final db = await AppDatabase.database;
    final id = _uuid.v4();
    final occurredStr = occurredAt.toUtc().toIso8601String();
    await db.insert(
      _table,
      {
        'id': id,
        'type': type,
        'debit_account_id': debitAccountId,
        'credit_account_id': creditAccountId,
        'amount': amount,
        'tag_ids': jsonEncode(tagIds),
        'memo': memo,
        'occurred_at': occurredStr,
      },
    );
  }
}
