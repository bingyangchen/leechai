import 'package:mobile/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class TagRepository {
  TagRepository._();

  static const String _table = 'tag';
  static const String _entryTagTable = 'entry_tag';
  static final _uuid = Uuid();

  static Future<List<Map<String, Object?>>> getAllOrderByCreatedAt() async {
    final db = await AppDatabase.database;
    return db.query(
      _table,
      columns: ['id', 'title', 'created_at'],
      where: 'deleted_at IS NULL',
      orderBy: 'created_at ASC',
    );
  }

  static Future<Map<String, Object?>?> getById(String id) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      columns: ['id', 'title', 'created_at'],
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single;
  }

  static Future<int> getUsageCount(String tagId) async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c '
      'FROM $_entryTagTable et '
      'JOIN entry e ON e.id = et.entry_id '
      'WHERE et.tag_id = ? '
      'AND et.deleted_at IS NULL '
      'AND e.deleted_at IS NULL',
      [tagId],
    );
    return (rows.single['c'] as int?) ?? 0;
  }

  static Future<Map<String, int>> getUsageCountsForTagIds(List<String> tagIds) async {
    if (tagIds.isEmpty) return {};
    final db = await AppDatabase.database;
    final placeholders = List.filled(tagIds.length, '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT et.tag_id, COUNT(*) AS c '
      'FROM $_entryTagTable et '
      'JOIN entry e ON e.id = et.entry_id '
      'WHERE et.tag_id IN ($placeholders) '
      'AND et.deleted_at IS NULL '
      'AND e.deleted_at IS NULL '
      'GROUP BY et.tag_id',
      tagIds,
    );
    return {for (final r in rows) r['tag_id'] as String: r['c'] as int};
  }

  static Future<bool> existsByTitle(String title, {String? excludeId}) async {
    final db = await AppDatabase.database;
    final trimmed = title.trim();
    final where = excludeId == null
        ? 'title = ? AND deleted_at IS NULL'
        : 'title = ? AND deleted_at IS NULL AND id != ?';
    final whereArgs = excludeId == null ? [trimmed] : [trimmed, excludeId];
    final rows = await db.query(
      _table,
      columns: ['id'],
      where: where,
      whereArgs: whereArgs,
    );
    return rows.isNotEmpty;
  }

  static Future<void> updateTitle(String id, String title) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      _table,
      {'title': title.trim(), 'updated_at': now, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
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
    await db.update(
      _entryTagTable,
      {'deleted_at': now, 'updated_at': now, 'synced': 0},
      where: 'tag_id = ?',
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
    await db.update(
      _entryTagTable,
      {'deleted_at': null, 'updated_at': now, 'synced': 0},
      where: 'tag_id = ?',
      whereArgs: [id],
    );
  }

  static Future<String> getOrCreateByTitle(String title) async {
    final db = await AppDatabase.database;
    final trimmed = title.trim();
    final existing = await db.query(
      _table,
      columns: ['id'],
      where: 'title = ? AND deleted_at IS NULL',
      whereArgs: [trimmed],
    );
    if (existing.isNotEmpty) return existing.first['id'] as String;

    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(_table, {
      'id': id,
      'title': trimmed,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  static Future<List<String>> searchByTitlePrefix(String query) async {
    final db = await AppDatabase.database;
    final prefix = query.trim();
    if (prefix.isEmpty) return [];
    final rows = await db.query(
      _table,
      columns: ['title'],
      where: 'deleted_at IS NULL AND title LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'title',
    );
    return rows.map((r) => r['title'] as String).toList();
  }

  static Future<Map<String, String>> getTitlesByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final db = await AppDatabase.database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.query(
      _table,
      columns: ['id', 'title'],
      where: 'deleted_at IS NULL AND id IN ($placeholders)',
      whereArgs: ids,
    );
    return {for (final r in rows) r['id'] as String: r['title'] as String};
  }
}
