import 'package:flutter/material.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/account/domain/account_icon.dart';
import 'package:mobile/features/account/domain/constants.dart';
import 'package:mobile/features/budget/data/repositories/budget.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

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
      orderBy: 'last_used_at DESC, id ASC',
    );
    return rows.map(_rowToAccount).toList();
  }

  static Future<List<Account>> getByTypeOrderByCreatedAt(String type) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      _table,
      where: 'type = ? AND deleted_at IS NULL',
      whereArgs: [type],
      orderBy: 'created_at ASC, id ASC',
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

  static Future<String> ensureTransferFeeExpenseAccountExists() async {
    final id = defaultExpenseTransferFeeId;
    final existing = await getById(id);
    if (existing != null) return id;

    final db = await AppDatabase.database;
    final deletedRow = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (deletedRow.isNotEmpty) {
      await restore(id);
      return id;
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(_table, {
      'id': id,
      'type': AccountType.expense.name,
      'sub_type': '手續費',
      'icon': iconToCodePoint(Icons.more_horiz),
      'last_used_at': now,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    return (await getById(id))?.id ?? id;
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

  static final _uuid = Uuid();

  static Future<Account> insert({
    required AccountType type,
    required String subType,
    required String name,
    required double initialBalance,
    IconData? icon,
  }) async {
    final db = await AppDatabase.database;
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(_table, {
      'id': id,
      'type': type.name,
      'sub_type': subType,
      'name': name,
      'icon': icon != null ? iconToCodePoint(icon) : null,
      'initial_balance': initialBalance,
      'last_used_at': now,
      'created_at': now,
      'updated_at': now,
    });
    return (await getById(id))!;
  }

  static Future<void> updateLastUsedAt(String accountId) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      _table,
      {'last_used_at': now, 'updated_at': now, 'synced': 0},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  static Future<void> batchUpdateLastUsedAt(Iterable<String> accountIds) async {
    final unique = accountIds.toSet();
    await Future.wait(unique.map(updateLastUsedAt));
  }

  static Future<void> update({
    required String id,
    required String name,
    required double initialBalance,
    IconData? icon,
    String? subType,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    final data = <String, Object?>{
      'name': name,
      'initial_balance': initialBalance,
      'icon': icon != null ? iconToCodePoint(icon) : null,
      'updated_at': now,
      'synced': 0,
    };
    if (subType != null) data['sub_type'] = subType;
    await db.update(
      _table,
      data,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  static Future<bool> softDelete(String accountId) async {
    final db = await AppDatabase.database;
    final entries = await db.query(
      'entry',
      columns: ['id'],
      where: 'deleted_at IS NULL AND (debit_account_id = ? OR credit_account_id = ?)',
      whereArgs: [accountId, accountId],
    );
    if (entries.isNotEmpty) return false;

    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      _table,
      {'deleted_at': now, 'updated_at': now, 'synced': 0},
      where: 'id = ?',
      whereArgs: [accountId],
    );
    await BudgetRepository.deleteCategoryBudgetsByAccountId(accountId);
    return true;
  }

  static Future<void> restore(String accountId) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      _table,
      {'deleted_at': null, 'updated_at': now, 'synced': 0},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  static Account _rowToAccount(Map<String, Object?> row) {
    return Account(
      id: row['id'] as String,
      name: row['name'] as String?,
      type: _parseAccountType(row['type'] as String? ?? 'asset'),
      subType: row['sub_type'] as String? ?? '',
      icon: iconFromCodePoint(row['icon'] as String?),
      initialBalance: (row['initial_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static AccountType _parseAccountType(String typeStr) {
    switch (typeStr) {
      case 'liability':
        return AccountType.liability;
      case 'expense':
        return AccountType.expense;
      case 'income':
        return AccountType.income;
      case 'equity':
        return AccountType.equity;
      case 'asset':
      default:
        return AccountType.asset;
    }
  }
}
