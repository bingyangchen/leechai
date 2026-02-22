import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/account/domain/account_icon.dart';

class AccountRepository {
  AccountRepository._();

  static const String _table = 'account';

  static Future<List<Account>> getAll() async {
    final db = await AppDatabase.database;
    final rows = await db.query(_table, where: 'deleted_at IS NULL', orderBy: 'id');
    return rows.map(_rowToAccount).toList();
  }

  static Future<List<Account>> getByType(String type) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      where: 'type = ? AND deleted_at IS NULL',
      whereArgs: [type],
      orderBy: 'id',
    );
    return rows.map(_rowToAccount).toList();
  }

  static Future<List<Account>> getBalanceAccounts() async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      where: "type IN ('asset', 'liability') AND deleted_at IS NULL",
      orderBy: 'last_used_at DESC',
    );
    return rows.map(_rowToAccount).toList();
  }

  static Future<Account?> getById(String id) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return _rowToAccount(rows.single);
  }

  static Account _rowToAccount(Map<String, Object?> row) {
    final id = row['id'] as String;
    final name = row['name'] as String?;
    final typeStr = row['type'] as String? ?? 'asset';
    final subTypeStr = row['sub_type'] as String? ?? '';
    final type = _parseAccountType(typeStr);
    final icon = iconFromCodePoint(row['icon'] as String?);
    return Account(id: id, name: name, type: type, subType: subTypeStr, icon: icon);
  }

  static AccountType _parseAccountType(String typeStr) {
    switch (typeStr) {
      case 'liability':
        return AccountType.liability;
      case 'expense':
        return AccountType.expense;
      case 'income':
        return AccountType.income;
      case 'asset':
      default:
        return AccountType.asset;
    }
  }
}
