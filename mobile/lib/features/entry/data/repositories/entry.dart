import 'package:mobile/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class EntryRepository {
  EntryRepository._();

  static const String _table = 'entry';
  static const String _entryTagTable = 'entry_tag';
  static final _uuid = Uuid();

  static Future<List<Map<String, Object?>>> getAll() async {
    final db = await AppDatabase.database;
    return db.query(_table, where: 'deleted_at IS NULL', orderBy: 'occurred_at DESC');
  }

  static Future<List<String>> getTagIdsForEntry(String entryId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _entryTagTable,
      columns: ['tag_id'],
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );
    return rows.map((r) => r['tag_id'] as String).toList();
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
    await db.insert(_table, {
      'id': id,
      'type': type,
      'debit_account_id': debitAccountId,
      'credit_account_id': creditAccountId,
      'amount': amount,
      'memo': memo,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
    });
    for (final tagId in tagIds) {
      await db.insert(_entryTagTable, {'entry_id': id, 'tag_id': tagId});
    }
  }
}
