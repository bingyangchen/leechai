import 'package:mobile/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

class BudgetRepository {
  BudgetRepository._();

  static const String _budgetTable = 'budget';
  static const String _categoryTable = 'category_budget';
  static final _uuid = Uuid();

  static Future<double?> getTotalForMonth(int year, int month) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _budgetTable,
      columns: ['total_amount'],
      where: 'year = ? AND month = ? AND deleted_at IS NULL',
      whereArgs: [year, month],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.single['total_amount'] as num?)?.toDouble();
  }

  static Future<void> upsertTotalForMonth(int year, int month, double amount) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    final existing = await db.query(
      _budgetTable,
      columns: ['id'],
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert(_budgetTable, {
        'id': _uuid.v4(),
        'year': year,
        'month': month,
        'total_amount': amount,
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      });
    } else {
      await db.update(
        _budgetTable,
        {'total_amount': amount, 'updated_at': now, 'synced': 0, 'deleted_at': null},
        where: 'year = ? AND month = ?',
        whereArgs: [year, month],
      );
    }
  }

  static Future<void> clearTotalForMonth(int year, int month) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      _budgetTable,
      {'deleted_at': now, 'updated_at': now, 'synced': 0},
      where: 'year = ? AND month = ? AND deleted_at IS NULL',
      whereArgs: [year, month],
    );
  }

  static Future<Map<String, double>> getCategoryBudgetsForMonth(
    int year,
    int month,
  ) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _categoryTable,
      columns: ['sub_type', 'amount'],
      where: 'year = ? AND month = ? AND deleted_at IS NULL',
      whereArgs: [year, month],
    );
    return {
      for (final row in rows)
        row['sub_type'] as String: (row['amount'] as num?)?.toDouble() ?? 0,
    };
  }

  static Future<void> upsertCategoryBudget(
    int year,
    int month,
    String subType,
    double amount,
  ) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    final existing = await db.query(
      _categoryTable,
      columns: ['id'],
      where: 'year = ? AND month = ? AND sub_type = ?',
      whereArgs: [year, month, subType],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert(_categoryTable, {
        'id': _uuid.v4(),
        'year': year,
        'month': month,
        'sub_type': subType,
        'amount': amount,
        'created_at': now,
        'updated_at': now,
        'synced': 0,
      });
    } else {
      await db.update(
        _categoryTable,
        {'amount': amount, 'updated_at': now, 'synced': 0, 'deleted_at': null},
        where: 'year = ? AND month = ? AND sub_type = ?',
        whereArgs: [year, month, subType],
      );
    }
  }

  static Future<void> deleteCategoryBudget(int year, int month, String subType) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      _categoryTable,
      {'deleted_at': now, 'updated_at': now, 'synced': 0},
      where: 'year = ? AND month = ? AND sub_type = ? AND deleted_at IS NULL',
      whereArgs: [year, month, subType],
    );
  }
}
