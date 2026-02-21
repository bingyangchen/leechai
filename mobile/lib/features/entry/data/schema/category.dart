import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute('''
  CREATE TABLE IF NOT EXISTS category (
    id TEXT PRIMARY KEY,
    entry_type TEXT NOT NULL,
    name TEXT NOT NULL,
    parent_id TEXT,
    icon TEXT,
    created_at TEXT NOT NULL DEFAULT (DATETIME('now')),
    deleted_at TEXT
  );
  ''');
  await seedDefaults(db);
}

Future<void> seedDefaults(Database db) async {
  // expense
  await _seedEntryTypeCategories(
    db,
    entryType: 'expense',
    mains: [
      (
        id: 'expense_main_0',
        name: '飲食',
        iconCodePoint: Icons.restaurant.codePoint,
      ),
      (
        id: 'expense_main_1',
        name: '交通',
        iconCodePoint: Icons.directions_car.codePoint,
      ),
      (
        id: 'expense_main_2',
        name: '居家',
        iconCodePoint: Icons.home.codePoint,
      ),
      (
        id: 'expense_main_3',
        name: '娛樂',
        iconCodePoint: Icons.movie.codePoint,
      ),
      (
        id: 'expense_main_4',
        name: '購物',
        iconCodePoint: Icons.shopping_bag.codePoint,
      ),
      (
        id: 'expense_main_5',
        name: '其他',
        iconCodePoint: Icons.more_horiz.codePoint,
      ),
    ],
    subs: [
      (parentId: 'expense_main_0', name: '早餐'),
      (parentId: 'expense_main_0', name: '午餐'),
      (parentId: 'expense_main_0', name: '晚餐'),
      (parentId: 'expense_main_0', name: '飲料'),
      (parentId: 'expense_main_0', name: '零食'),
      (parentId: 'expense_main_0', name: '超市'),
      (parentId: 'expense_main_1', name: '捷運'),
      (parentId: 'expense_main_1', name: '公車'),
      (parentId: 'expense_main_1', name: '計程車'),
      (parentId: 'expense_main_1', name: '油費'),
      (parentId: 'expense_main_1', name: '停車'),
      (parentId: 'expense_main_2', name: '房租'),
      (parentId: 'expense_main_2', name: '水電'),
      (parentId: 'expense_main_2', name: '瓦斯'),
      (parentId: 'expense_main_2', name: '網路'),
      (parentId: 'expense_main_2', name: '傢俱'),
      (parentId: 'expense_main_3', name: '電影'),
      (parentId: 'expense_main_3', name: '遊戲'),
      (parentId: 'expense_main_3', name: '運動'),
      (parentId: 'expense_main_3', name: '旅遊'),
      (parentId: 'expense_main_4', name: '服飾'),
      (parentId: 'expense_main_4', name: '日用品'),
      (parentId: 'expense_main_4', name: '3C'),
    ],
  );

  // income
  await _seedEntryTypeCategories(
    db,
    entryType: 'income',
    mains: [
      (
        id: 'income_main_0',
        name: '薪資',
        iconCodePoint: Icons.account_balance_wallet.codePoint,
      ),
      (
        id: 'income_main_1',
        name: '獎金',
        iconCodePoint: Icons.card_giftcard.codePoint,
      ),
      (
        id: 'income_main_2',
        name: '投資',
        iconCodePoint: Icons.trending_up.codePoint,
      ),
      (
        id: 'income_main_3',
        name: '禮金',
        iconCodePoint: Icons.redeem.codePoint,
      ),
      (
        id: 'income_main_4',
        name: '其他',
        iconCodePoint: Icons.more_horiz.codePoint,
      ),
    ],
    subs: [
      (parentId: 'income_main_0', name: '本薪'),
      (parentId: 'income_main_0', name: '加班'),
      (parentId: 'income_main_0', name: '外快'),
      (parentId: 'income_main_1', name: '年終'),
      (parentId: 'income_main_1', name: '績效'),
      (parentId: 'income_main_2', name: '利息'),
      (parentId: 'income_main_2', name: '股利'),
      (parentId: 'income_main_3', name: '紅包'),
      (parentId: 'income_main_3', name: '禮品'),
    ],
  );
}

Future<void> _seedEntryTypeCategories(
  Database db, {
  required String entryType,
  required List<({String id, String name, int iconCodePoint})> mains,
  required List<({String parentId, String name})> subs,
}) async {
  for (final c in mains) {
    await db.insert(
      'category',
      {
        'id': c.id,
        'entry_type': entryType,
        'name': c.name,
        'icon': c.iconCodePoint.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
  var subIndex = 0;
  String? lastParentId;
  for (final s in subs) {
    if (s.parentId != lastParentId) {
      lastParentId = s.parentId;
      subIndex = 0;
    }
    await db.insert(
      'category',
      {
        'id': '${s.parentId}_sub_$subIndex',
        'entry_type': entryType,
        'name': s.name,
        'parent_id': s.parentId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    subIndex++;
  }
}
