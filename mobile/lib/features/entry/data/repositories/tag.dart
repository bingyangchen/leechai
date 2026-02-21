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
}
