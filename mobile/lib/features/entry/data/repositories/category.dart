import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/entry/domain/category.dart';

class CategoryRepository {
  CategoryRepository._();

  static const String _table = 'category';

  static Future<List<Category>> getMainCategories(String entryTypeId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      where: 'entry_type = ? AND parent_id IS NULL AND deleted_at IS NULL',
      whereArgs: [entryTypeId],
      orderBy: 'id',
    );
    return rows.map(_rowToCategory).toList();
  }

  static Future<List<Category>> getSubCategories(String parentId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      where: 'parent_id = ? AND deleted_at IS NULL',
      whereArgs: [parentId],
      orderBy: 'id',
    );
    return rows.map(_rowToCategory).toList();
  }

  static Category _rowToCategory(Map<String, Object?> row) {
    return Category(
      id: row['id'] as String,
      name: row['name'] as String,
      icon: row['icon'] as String?,
      parentId: row['parent_id'] as String?,
    );
  }
}
