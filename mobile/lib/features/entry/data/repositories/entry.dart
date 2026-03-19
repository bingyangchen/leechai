import 'package:mobile/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class EntryRepository {
  EntryRepository._();

  static const String _table = 'entry';
  static const String _entryTagTable = 'entry_tag';
  static final _uuid = Uuid();

  static Future<int> getCount() async {
    final db = await AppDatabase.database;
    final r = await db.query(
      _table,
      columns: ['COUNT(*) AS c'],
      where: 'deleted_at IS NULL',
    );
    return (r.single['c'] as int?) ?? 0;
  }

  static Future<DateTime?> getEarliestCreatedAt() async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      columns: ['created_at'],
      where: 'deleted_at IS NULL',
      orderBy: 'created_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final value = rows.single['created_at'];
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  static Future<List<Map<String, Object?>>> getAll() async {
    final db = await AppDatabase.database;
    return db.query(_table, where: 'deleted_at IS NULL', orderBy: 'occurred_at DESC');
  }

  static Future<List<Map<String, Object?>>> getByAccountId(String accountId) async {
    final db = await AppDatabase.database;
    return db.query(
      _table,
      where: 'deleted_at IS NULL AND (debit_account_id = ? OR credit_account_id = ?)',
      whereArgs: [accountId, accountId],
      orderBy: 'occurred_at DESC',
    );
  }

  static Future<List<Map<String, Object?>>> getByMonth(DateTime yearMonth) async {
    final db = await AppDatabase.database;
    final start = DateTime(yearMonth.year, yearMonth.month, 1);
    final end = DateTime(yearMonth.year, yearMonth.month + 1, 0, 23, 59, 59, 999);
    final startStr = start.toUtc().toIso8601String();
    final endStr = end.toUtc().toIso8601String();
    return db.query(
      _table,
      where: 'deleted_at IS NULL AND occurred_at >= ? AND occurred_at <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'occurred_at DESC',
    );
  }

  static Future<List<Map<String, Object?>>> getByOccurredAtDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await AppDatabase.database;
    final startStr = start.toUtc().toIso8601String();
    final endStr = end.toUtc().toIso8601String();
    return db.query(
      _table,
      where: 'deleted_at IS NULL AND occurred_at >= ? AND occurred_at <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'occurred_at ASC',
    );
  }

  static Future<List<Map<String, Object?>>> getByCreatedAtDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await AppDatabase.database;
    final startStr = start.toUtc().toIso8601String();
    final endStr = end.toUtc().toIso8601String();
    return db.query(
      _table,
      where: 'deleted_at IS NULL AND created_at >= ? AND created_at <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'created_at ASC',
    );
  }

  static Future<List<Map<String, Object?>>> getUpTo(DateTime end) async {
    final db = await AppDatabase.database;
    final endStr = end.toUtc().toIso8601String();
    return db.query(
      _table,
      where: 'deleted_at IS NULL AND occurred_at <= ?',
      whereArgs: [endStr],
      orderBy: 'occurred_at ASC',
    );
  }

  static Future<void> softDelete(String id) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      _table,
      {'deleted_at': now, 'updated_at': now, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> restore(String id) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      _table,
      {'deleted_at': null, 'updated_at': now, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<String> duplicate(String entryId, DateTime occurredAt) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [entryId],
    );
    if (rows.isEmpty) throw StateError('Entry not found: $entryId');
    final row = rows.single;
    final tagIds = await getTagIdsForEntry(entryId);
    final newId = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(_table, {
      'id': newId,
      'type': row['type'],
      'debit_account_id': row['debit_account_id'],
      'credit_account_id': row['credit_account_id'],
      'amount': row['amount'],
      'memo': row['memo'],
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'created_at': now,
      'updated_at': now,
    });
    for (final tagId in tagIds) {
      await db.insert(_entryTagTable, {
        'entry_id': newId,
        'tag_id': tagId,
        'updated_at': now,
      });
    }
    return newId;
  }

  static Future<Map<String, Object?>?> getById(String id) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : rows.single;
  }

  static Future<List<String>> getTagIdsForEntry(String entryId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _entryTagTable,
      columns: ['tag_id'],
      where: 'entry_id = ? AND deleted_at IS NULL',
      whereArgs: [entryId],
    );
    return rows.map((r) => r['tag_id'] as String).toList();
  }

  static Future<void> update({
    required String id,
    required String type,
    required String debitAccountId,
    required String creditAccountId,
    required double amount,
    required List<String> tagIds,
    String? memo,
    required DateTime occurredAt,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      _table,
      {
        'type': type,
        'debit_account_id': debitAccountId,
        'credit_account_id': creditAccountId,
        'amount': amount,
        'memo': memo,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'updated_at': now,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.update(
      _entryTagTable,
      {'deleted_at': now, 'updated_at': now, 'synced': 0},
      where: 'entry_id = ?',
      whereArgs: [id],
    );
    for (final tagId in tagIds) {
      await db.insert(_entryTagTable, {
        'entry_id': id,
        'tag_id': tagId,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
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
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(_table, {
      'id': id,
      'type': type,
      'debit_account_id': debitAccountId,
      'credit_account_id': creditAccountId,
      'amount': amount,
      'memo': memo,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'created_at': now,
      'updated_at': now,
    });
    for (final tagId in tagIds) {
      await db.insert(_entryTagTable, {
        'entry_id': id,
        'tag_id': tagId,
        'updated_at': now,
      });
    }
  }
}
