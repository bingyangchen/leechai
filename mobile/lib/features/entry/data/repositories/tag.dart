import 'package:mobile/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class TagRepository {
  TagRepository._();

  static const String _table = 'tag';
  static final _uuid = Uuid();

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
    await db.insert(_table, {'id': id, 'title': trimmed});
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
}
