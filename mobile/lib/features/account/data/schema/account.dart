import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/constants.dart'
    show defaultEquityUnrealizedGainId, defaultExpenseTransferFeeId;
import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute("""
  CREATE TABLE IF NOT EXISTS account (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    sub_type TEXT NOT NULL,
    name TEXT,
    icon TEXT,
    initial_balance REAL NOT NULL DEFAULT 0,
    last_used_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    created_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    updated_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    deleted_at TEXT,
    synced INTEGER NOT NULL DEFAULT 0
  );
  """);
  await seedDefaults(db);
}

Future<void> seedDefaults(Database db) async {
  final now = DateTime.now().toUtc().toIso8601String();
  // Assets
  await db.insert('account', {
    'id': 'default_cash',
    'type': 'asset',
    'sub_type': 'cash',
    'name': '現金',
    'icon': Icons.wallet.codePoint.toString(),
    'last_used_at': now,
    'created_at': now,
    'updated_at': now,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);
  await db.insert('account', {
    'id': 'default_bank',
    'type': 'asset',
    'sub_type': 'bank',
    'name': '銀行',
    'icon': Icons.account_balance.codePoint.toString(),
    'last_used_at': now,
    'created_at': now,
    'updated_at': now,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);

  // Liabilities
  await db.insert('account', {
    'id': 'default_loan',
    'type': 'liability',
    'sub_type': 'loan',
    'name': '貸款',
    'icon': Icons.credit_card.codePoint.toString(),
    'last_used_at': now,
    'created_at': now,
    'updated_at': now,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);
  await db.insert('account', {
    'id': 'default_credit_card',
    'type': 'liability',
    'sub_type': 'creditCard',
    'name': '信用卡',
    'icon': Icons.credit_card.codePoint.toString(),
    'last_used_at': now,
    'created_at': now,
    'updated_at': now,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);

  // Expense
  final expenseAccounts = [
    ('default_expense_0', '飲食', Icons.restaurant.codePoint.toString()),
    ('default_expense_1', '交通', Icons.directions_bus.codePoint.toString()),
    ('default_expense_2', '居家', Icons.home.codePoint.toString()),
    ('default_expense_3', '娛樂', Icons.movie.codePoint.toString()),
    ('default_expense_4', '購物', Icons.shopping_bag.codePoint.toString()),
    ('default_expense_5', '其他', Icons.more_horiz.codePoint.toString()),
    (defaultExpenseTransferFeeId, '手續費', Icons.more_horiz.codePoint.toString()),
  ];
  for (final (id, subType, icon) in expenseAccounts) {
    await db.insert('account', {
      'id': id,
      'type': 'expense',
      'sub_type': subType,
      'icon': icon,
      'last_used_at': now,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Income
  final incomeAccounts = [
    ('default_income_0', '薪資', Icons.work.codePoint.toString()),
    ('default_income_1', '獎金', Icons.stars.codePoint.toString()),
    ('default_income_2', '投資', Icons.trending_up.codePoint.toString()),
    ('default_income_3', '禮金', Icons.card_giftcard.codePoint.toString()),
    ('default_income_4', '其他', Icons.more_horiz.codePoint.toString()),
  ];
  for (final (id, subType, icon) in incomeAccounts) {
    await db.insert('account', {
      'id': id,
      'type': 'income',
      'sub_type': subType,
      'icon': icon,
      'last_used_at': now,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Equity
  await db.insert('account', {
    'id': defaultEquityUnrealizedGainId,
    'type': 'equity',
    'sub_type': 'unrealizedGain',
    'name': '未實現損益',
    'icon': Icons.balance.codePoint.toString(),
    'last_used_at': now,
    'created_at': now,
    'updated_at': now,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);
}
