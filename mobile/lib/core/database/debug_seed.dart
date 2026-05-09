import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/domain/constants.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:sqflite/sqflite.dart';

Future<void> seedDebugData(Database db) async {
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);
  final previousMonth = DateTime(now.year, now.month - 1);
  final currentMonthLatestDay = now.day;

  await _insertAccounts(db, currentMonth);
  await _insertTags(db, currentMonth);
  await _insertBudgets(db, currentMonth, previousMonth);
  await _insertEntries(db, currentMonth, previousMonth, currentMonthLatestDay);
}

Future<void> _insertAccounts(Database db, DateTime currentMonth) async {
  final timestamp = _timestamp(currentMonth, 1, 8);
  final accounts = [
    (
      id: 'debug_cash',
      type: 'asset',
      subType: 'cash',
      name: '測試現金',
      icon: Icons.wallet.codePoint.toString(),
      initialBalance: 3600.0,
    ),
    (
      id: 'debug_checking',
      type: 'asset',
      subType: 'bank',
      name: '測試活存',
      icon: Icons.account_balance.codePoint.toString(),
      initialBalance: 42800.0,
    ),
    (
      id: 'debug_savings',
      type: 'asset',
      subType: 'bank',
      name: '測試儲蓄',
      icon: Icons.savings.codePoint.toString(),
      initialBalance: 120000.0,
    ),
    (
      id: 'debug_investment',
      type: 'asset',
      subType: AssetType.securities.name,
      name: '測試台股帳戶',
      icon: AssetType.securities.icon.codePoint.toString(),
      initialBalance: 85000.0,
    ),
    (
      id: 'debug_credit_card',
      type: 'liability',
      subType: 'creditCard',
      name: '測試信用卡',
      icon: Icons.credit_card.codePoint.toString(),
      initialBalance: 5600.0,
    ),
    (
      id: 'debug_student_loan',
      type: 'liability',
      subType: 'loan',
      name: '測試貸款',
      icon: Icons.request_quote.codePoint.toString(),
      initialBalance: 80000.0,
    ),
  ];

  for (final account in accounts) {
    await db.insert('account', {
      'id': account.id,
      'type': account.type,
      'sub_type': account.subType,
      'name': account.name,
      'icon': account.icon,
      'initial_balance': account.initialBalance,
      'last_used_at': timestamp,
      'created_at': timestamp,
      'updated_at': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

Future<void> _insertTags(Database db, DateTime currentMonth) async {
  final tags = [
    ('debug_tag_work', '工作'),
    ('debug_tag_family', '家庭'),
    ('debug_tag_subscription', '訂閱'),
    ('debug_tag_reimbursable', '可報銷'),
    ('debug_tag_cash', '現金'),
    ('debug_tag_commute', '通勤'),
    ('debug_tag_food', '外食'),
    ('debug_tag_errand', '跑腿'),
    ('debug_tag_weekend', '週末'),
    ('debug_tag_health', '健康'),
    ('debug_tag_home', '家用'),
    ('debug_tag_social', '聚會'),
  ];

  for (var i = 0; i < tags.length; i++) {
    final (id, title) = tags[i];
    final timestamp = _timestamp(currentMonth, 1 + i, 9);
    await db.insert('tag', {
      'id': id,
      'title': title,
      'created_at': timestamp,
      'updated_at': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

Future<void> _insertBudgets(
  Database db,
  DateTime currentMonth,
  DateTime previousMonth,
) async {
  await _insertBudget(db, currentMonth, 36000);
  await _insertBudget(db, previousMonth, 32000);

  await _insertCategoryBudget(db, currentMonth, 'default_expense_0', 12000);
  await _insertCategoryBudget(db, currentMonth, 'default_expense_1', 4200);
  await _insertCategoryBudget(db, currentMonth, 'default_expense_2', 8500);
  await _insertCategoryBudget(db, currentMonth, 'default_expense_3', 3600);
  await _insertCategoryBudget(db, currentMonth, 'default_expense_4', 5200);
}

Future<void> _insertEntries(
  Database db,
  DateTime currentMonth,
  DateTime previousMonth,
  int currentMonthLatestDay,
) async {
  final entries = [
    _DebugEntry(
      id: 'debug_entry_salary_current',
      type: EntryType.income,
      debitAccountId: 'debug_checking',
      creditAccountId: 'default_income_0',
      amount: 68000,
      memo: '本月薪資',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 5, 9),
      tagIds: const ['debug_tag_work'],
    ),
    _DebugEntry(
      id: 'debug_entry_lunch_current',
      type: EntryType.expense,
      debitAccountId: 'default_expense_0',
      creditAccountId: 'debug_cash',
      amount: 185,
      memo: '午餐',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 6, 12),
    ),
    _DebugEntry(
      id: 'debug_entry_grocery_current',
      type: EntryType.expense,
      debitAccountId: 'default_expense_0',
      creditAccountId: 'debug_credit_card',
      amount: 1260,
      memo: '週末採買',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 7, 18),
      tagIds: const ['debug_tag_family'],
    ),
    _DebugEntry(
      id: 'debug_entry_metro_current',
      type: EntryType.expense,
      debitAccountId: 'default_expense_1',
      creditAccountId: 'debug_cash',
      amount: 80,
      memo: '捷運',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 8, 8),
    ),
    _DebugEntry(
      id: 'debug_entry_rent_current',
      type: EntryType.expense,
      debitAccountId: 'default_expense_2',
      creditAccountId: 'debug_checking',
      amount: 18000,
      memo: '房租',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 10, 10),
    ),
    _DebugEntry(
      id: 'debug_entry_streaming_current',
      type: EntryType.expense,
      debitAccountId: 'default_expense_3',
      creditAccountId: 'debug_credit_card',
      amount: 390,
      memo: '影音訂閱',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 12, 21),
      tagIds: const ['debug_tag_subscription'],
    ),
    _DebugEntry(
      id: 'debug_entry_transfer_current',
      type: EntryType.transfer,
      debitAccountId: 'debug_savings',
      creditAccountId: 'debug_checking',
      amount: 10000,
      memo: '轉入儲蓄',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 15, 14),
    ),
    _DebugEntry(
      id: 'debug_entry_transfer_fee_current',
      type: EntryType.expense,
      debitAccountId: defaultExpenseTransferFeeId,
      creditAccountId: 'debug_checking',
      amount: 15,
      memo: '【轉帳手續費】測試活存 → 測試儲蓄',
      occurredAt: _currentMonthTimestamp(
        currentMonth,
        currentMonthLatestDay,
        15,
        14,
        minute: 1,
      ),
    ),
    _DebugEntry(
      id: 'debug_entry_borrow_current',
      type: EntryType.borrow,
      debitAccountId: 'debug_checking',
      creditAccountId: 'debug_student_loan',
      amount: 12000,
      memo: '短期借款',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 18, 11),
    ),
    _DebugEntry(
      id: 'debug_entry_repay_current',
      type: EntryType.repay,
      debitAccountId: 'debug_credit_card',
      creditAccountId: 'debug_checking',
      amount: 4500,
      memo: '信用卡繳款',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 22, 16),
    ),
    _DebugEntry(
      id: 'debug_entry_bonus_previous',
      type: EntryType.income,
      debitAccountId: 'debug_checking',
      creditAccountId: 'default_income_1',
      amount: 12000,
      memo: '上月獎金',
      occurredAt: _timestamp(previousMonth, 20, 9),
      tagIds: const ['debug_tag_work'],
    ),
    _DebugEntry(
      id: 'debug_entry_dinner_previous',
      type: EntryType.expense,
      debitAccountId: 'default_expense_0',
      creditAccountId: 'debug_credit_card',
      amount: 1680,
      memo: '家庭聚餐',
      occurredAt: _timestamp(previousMonth, 21, 19),
      tagIds: const ['debug_tag_family'],
    ),
    _DebugEntry(
      id: 'debug_entry_shopping_previous',
      type: EntryType.expense,
      debitAccountId: 'default_expense_4',
      creditAccountId: 'debug_credit_card',
      amount: 3200,
      memo: '換季購物',
      occurredAt: _timestamp(previousMonth, 24, 15),
    ),
    _DebugEntry(
      id: 'debug_entry_market_adjustment_previous',
      type: EntryType.adjustment,
      debitAccountId: 'debug_investment',
      creditAccountId: defaultEquityUnrealizedGainId,
      amount: 2300,
      memo: '市值更新',
      occurredAt: _timestamp(previousMonth, 26, 17),
    ),
    ..._cashTestEntries(currentMonth, previousMonth, currentMonthLatestDay),
    ..._investmentEntries(currentMonth, previousMonth, currentMonthLatestDay),
  ];

  for (final entry in entries) {
    await _insertEntry(db, entry);
  }
}

List<_DebugEntry> _investmentEntries(
  DateTime currentMonth,
  DateTime previousMonth,
  int currentMonthLatestDay,
) {
  return [
    _DebugEntry(
      id: 'debug_investment_buy_etf_previous',
      type: EntryType.transfer,
      debitAccountId: 'debug_investment',
      creditAccountId: 'debug_checking',
      amount: 25000,
      memo: '定期定額買進 ETF',
      occurredAt: _timestamp(previousMonth, 6, 10),
    ),
    _DebugEntry(
      id: 'debug_investment_buy_stock_previous',
      type: EntryType.transfer,
      debitAccountId: 'debug_investment',
      creditAccountId: 'debug_checking',
      amount: 18000,
      memo: '加碼台積電',
      occurredAt: _timestamp(previousMonth, 13, 10),
    ),
    _DebugEntry(
      id: 'debug_investment_market_gain_previous',
      type: EntryType.adjustment,
      debitAccountId: 'debug_investment',
      creditAccountId: defaultEquityUnrealizedGainId,
      amount: 6200,
      memo: '市值更新',
      occurredAt: _timestamp(previousMonth, 28, 16),
    ),
    _DebugEntry(
      id: 'debug_investment_dividend_current',
      type: EntryType.income,
      debitAccountId: 'debug_investment',
      creditAccountId: 'default_income_2',
      amount: 1350,
      memo: 'ETF 配息再投入',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 3, 10),
      tagIds: const ['debug_tag_work'],
    ),
    _DebugEntry(
      id: 'debug_investment_sell_current',
      type: EntryType.transfer,
      debitAccountId: 'debug_checking',
      creditAccountId: 'debug_investment',
      amount: 12000,
      memo: '部分獲利了結',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 9, 13),
    ),
    _DebugEntry(
      id: 'debug_investment_buy_bond_current',
      type: EntryType.transfer,
      debitAccountId: 'debug_investment',
      creditAccountId: 'debug_savings',
      amount: 15000,
      memo: '買進債券 ETF',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 14, 10),
    ),
    _DebugEntry(
      id: 'debug_investment_market_loss_current',
      type: EntryType.adjustment,
      debitAccountId: defaultEquityUnrealizedGainId,
      creditAccountId: 'debug_investment',
      amount: 2800,
      memo: '市值更新',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 24, 16),
    ),
  ];
}

List<_DebugEntry> _cashTestEntries(
  DateTime currentMonth,
  DateTime previousMonth,
  int currentMonthLatestDay,
) {
  final cashInEntries = [
    _DebugEntry(
      id: 'debug_cash_transfer_in_01',
      type: EntryType.transfer,
      debitAccountId: 'debug_cash',
      creditAccountId: 'debug_checking',
      amount: 2000,
      memo: 'ATM 提領現金',
      occurredAt: _timestamp(previousMonth, 3, 10),
      tagIds: const ['debug_tag_cash'],
    ),
    _DebugEntry(
      id: 'debug_cash_transfer_in_02',
      type: EntryType.transfer,
      debitAccountId: 'debug_cash',
      creditAccountId: 'debug_checking',
      amount: 1500,
      memo: '補充零用金',
      occurredAt: _timestamp(previousMonth, 17, 16),
      tagIds: const ['debug_tag_cash', 'debug_tag_family'],
    ),
    _DebugEntry(
      id: 'debug_cash_transfer_in_03',
      type: EntryType.transfer,
      debitAccountId: 'debug_cash',
      creditAccountId: 'debug_checking',
      amount: 1200,
      memo: 'ATM 提領現金',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 4, 10),
      tagIds: const ['debug_tag_cash'],
    ),
    _DebugEntry(
      id: 'debug_cash_transfer_in_04',
      type: EntryType.transfer,
      debitAccountId: 'debug_cash',
      creditAccountId: 'debug_checking',
      amount: 1000,
      memo: '補充錢包現金',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 16, 15),
      tagIds: const ['debug_tag_cash', 'debug_tag_weekend'],
    ),
    _DebugEntry(
      id: 'debug_cash_income_01',
      type: EntryType.income,
      debitAccountId: 'debug_cash',
      creditAccountId: 'default_income_4',
      amount: 600,
      memo: '朋友還零用款',
      occurredAt: _timestamp(previousMonth, 9, 18),
      tagIds: const ['debug_tag_cash', 'debug_tag_social'],
    ),
    _DebugEntry(
      id: 'debug_cash_income_02',
      type: EntryType.income,
      debitAccountId: 'debug_cash',
      creditAccountId: 'default_income_4',
      amount: 350,
      memo: '二手小物現金收入',
      occurredAt: _timestamp(previousMonth, 23, 13),
      tagIds: const ['debug_tag_cash'],
    ),
    _DebugEntry(
      id: 'debug_cash_income_03',
      type: EntryType.income,
      debitAccountId: 'debug_cash',
      creditAccountId: 'default_income_3',
      amount: 500,
      memo: '現金禮金',
      occurredAt: _currentMonthTimestamp(currentMonth, currentMonthLatestDay, 11, 19),
      tagIds: const ['debug_tag_cash', 'debug_tag_family'],
    ),
  ];

  final expenseSpecs = [
    _CashExpenseSpec(
      'default_expense_0',
      85,
      '早餐',
      tagIds: const ['debug_tag_cash', 'debug_tag_food'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      120,
      '咖啡',
      tagIds: const ['debug_tag_cash', 'debug_tag_food', 'debug_tag_work'],
    ),
    _CashExpenseSpec(
      'default_expense_1',
      45,
      '公車',
      tagIds: const ['debug_tag_cash', 'debug_tag_commute'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      160,
      '午餐',
      tagIds: const ['debug_tag_cash', 'debug_tag_food', 'debug_tag_work'],
    ),
    _CashExpenseSpec(
      'default_expense_5',
      55,
      '影印',
      tagIds: const ['debug_tag_cash', 'debug_tag_errand', 'debug_tag_reimbursable'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      220,
      '晚餐',
      tagIds: const ['debug_tag_cash', 'debug_tag_food'],
    ),
    _CashExpenseSpec(
      'default_expense_1',
      60,
      '捷運',
      tagIds: const ['debug_tag_commute'],
    ),
    _CashExpenseSpec(
      'default_expense_4',
      180,
      '生活用品',
      tagIds: const ['debug_tag_cash', 'debug_tag_home'],
    ),
    _CashExpenseSpec('default_expense_0', 95, '飲料', tagIds: const ['debug_tag_food']),
    _CashExpenseSpec(
      'default_expense_3',
      250,
      '展覽門票',
      tagIds: const ['debug_tag_cash', 'debug_tag_weekend'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      180,
      '點心',
      tagIds: const ['debug_tag_cash', 'debug_tag_food', 'debug_tag_family'],
    ),
    _CashExpenseSpec(
      'default_expense_1',
      80,
      '計程車分攤',
      tagIds: const ['debug_tag_cash', 'debug_tag_commute', 'debug_tag_social'],
    ),
    _CashExpenseSpec(
      'default_expense_2',
      260,
      '清潔用品',
      tagIds: const ['debug_tag_home'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      240,
      '便當',
      tagIds: const ['debug_tag_cash', 'debug_tag_food'],
    ),
    _CashExpenseSpec(
      'default_expense_5',
      100,
      '包裹寄送',
      tagIds: const ['debug_tag_errand'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      75,
      '手搖飲',
      tagIds: const ['debug_tag_cash', 'debug_tag_food'],
    ),
    _CashExpenseSpec(
      'default_expense_4',
      320,
      '文具',
      tagIds: const ['debug_tag_work', 'debug_tag_reimbursable'],
    ),
    _CashExpenseSpec(
      'default_expense_1',
      40,
      'YouBike',
      tagIds: const ['debug_tag_cash', 'debug_tag_commute'],
    ),
    _CashExpenseSpec('default_expense_0', 135, '麵包', tagIds: const ['debug_tag_food']),
    _CashExpenseSpec(
      'default_expense_3',
      180,
      '電影零食',
      tagIds: const ['debug_tag_cash', 'debug_tag_social', 'debug_tag_weekend'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      260,
      '牛肉麵',
      tagIds: const ['debug_tag_cash', 'debug_tag_food'],
    ),
    _CashExpenseSpec(
      'default_expense_1',
      55,
      '公車',
      tagIds: const ['debug_tag_commute'],
    ),
    _CashExpenseSpec(
      'default_expense_5',
      150,
      '臨時雜支',
      tagIds: const ['debug_tag_cash'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      90,
      '早餐',
      tagIds: const ['debug_tag_cash', 'debug_tag_food'],
    ),
    _CashExpenseSpec(
      'default_expense_4',
      280,
      '藥妝',
      tagIds: const ['debug_tag_health'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      155,
      '午餐',
      tagIds: const ['debug_tag_food', 'debug_tag_work'],
    ),
    _CashExpenseSpec(
      'default_expense_1',
      120,
      '停車費',
      tagIds: const ['debug_tag_cash', 'debug_tag_commute'],
    ),
    _CashExpenseSpec(
      'default_expense_2',
      300,
      '瓦斯費',
      tagIds: const ['debug_tag_home', 'debug_tag_family'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      210,
      '晚餐',
      tagIds: const ['debug_tag_cash', 'debug_tag_food', 'debug_tag_family'],
    ),
    _CashExpenseSpec(
      'default_expense_5',
      70,
      '列印文件',
      tagIds: const ['debug_tag_errand'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      110,
      '咖啡',
      tagIds: const ['debug_tag_cash', 'debug_tag_food'],
    ),
    _CashExpenseSpec(
      'default_expense_1',
      35,
      '短程公車',
      tagIds: const ['debug_tag_commute'],
    ),
    _CashExpenseSpec(
      'default_expense_4',
      190,
      '五金材料',
      tagIds: const ['debug_tag_home', 'debug_tag_errand'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      145,
      '午餐',
      tagIds: const ['debug_tag_cash', 'debug_tag_food'],
    ),
    _CashExpenseSpec(
      'default_expense_3',
      300,
      '桌遊聚會',
      tagIds: const ['debug_tag_cash', 'debug_tag_social', 'debug_tag_weekend'],
    ),
    _CashExpenseSpec('default_expense_0', 65, '飲料', tagIds: const ['debug_tag_food']),
    _CashExpenseSpec(
      'default_expense_1',
      50,
      '捷運',
      tagIds: const ['debug_tag_cash', 'debug_tag_commute'],
    ),
    _CashExpenseSpec('default_expense_2', 220, '洗衣', tagIds: const ['debug_tag_home']),
    _CashExpenseSpec(
      'default_expense_0',
      175,
      '晚餐',
      tagIds: const ['debug_tag_cash', 'debug_tag_food'],
    ),
    _CashExpenseSpec(
      'default_expense_5',
      85,
      '小費',
      tagIds: const ['debug_tag_cash', 'debug_tag_social'],
    ),
    _CashExpenseSpec(
      'default_expense_0',
      130,
      '早餐店',
      tagIds: const ['debug_tag_cash', 'debug_tag_food', 'debug_tag_weekend'],
    ),
    _CashExpenseSpec(
      'default_expense_1',
      70,
      '公車',
      tagIds: const ['debug_tag_commute'],
    ),
    _CashExpenseSpec(
      'default_expense_4',
      260,
      '日用品補貨',
      tagIds: const ['debug_tag_cash', 'debug_tag_home', 'debug_tag_family'],
    ),
  ];

  final expenseEntries = <_DebugEntry>[];
  for (var i = 0; i < expenseSpecs.length; i++) {
    final spec = expenseSpecs[i];
    final isPreviousMonth = i < 22;
    final day = isPreviousMonth ? 2 + i : 1 + (i - 22);
    final occurredAt = isPreviousMonth
        ? _timestamp(previousMonth, day, 8 + i % 12, minute: i % 4 * 10)
        : _currentMonthTimestamp(
            currentMonth,
            currentMonthLatestDay,
            day,
            8 + i % 12,
            minute: i % 4 * 10,
          );
    expenseEntries.add(
      _DebugEntry(
        id: 'debug_cash_expense_${(i + 1).toString().padLeft(2, '0')}',
        type: EntryType.expense,
        debitAccountId: spec.accountId,
        creditAccountId: 'debug_cash',
        amount: spec.amount,
        memo: spec.memo,
        occurredAt: occurredAt,
        tagIds: spec.tagIds,
      ),
    );
  }

  return [...cashInEntries, ...expenseEntries];
}

Future<void> _insertBudget(Database db, DateTime month, double amount) async {
  final timestamp = _timestamp(month, 1, 8);
  await db.insert('budget', {
    'id': 'debug_budget_${month.year}_${month.month}',
    'year': month.year,
    'month': month.month,
    'total_amount': amount,
    'created_at': timestamp,
    'updated_at': timestamp,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);
}

Future<void> _insertCategoryBudget(
  Database db,
  DateTime month,
  String accountId,
  double amount,
) async {
  final timestamp = _timestamp(month, 1, 8);
  await db.insert('category_budget', {
    'id': 'debug_category_budget_${month.year}_${month.month}_$accountId',
    'year': month.year,
    'month': month.month,
    'account_id': accountId,
    'amount': amount,
    'created_at': timestamp,
    'updated_at': timestamp,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);
}

Future<void> _insertEntry(Database db, _DebugEntry entry) async {
  await db.insert('entry', {
    'id': entry.id,
    'type': entry.type.name,
    'debit_account_id': entry.debitAccountId,
    'credit_account_id': entry.creditAccountId,
    'amount': entry.amount,
    'memo': entry.memo,
    'occurred_at': entry.occurredAt,
    'created_at': entry.occurredAt,
    'updated_at': entry.occurredAt,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);

  for (final tagId in entry.tagIds) {
    await db.insert('entry_tag', {
      'entry_id': entry.id,
      'tag_id': tagId,
      'updated_at': entry.occurredAt,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}

String _timestamp(DateTime month, int day, int hour, {int minute = 0}) {
  return DateTime(month.year, month.month, day, hour, minute).toUtc().toIso8601String();
}

String _currentMonthTimestamp(
  DateTime month,
  int latestDay,
  int preferredDay,
  int hour, {
  int minute = 0,
}) {
  final day = preferredDay > latestDay ? latestDay : preferredDay;
  return _timestamp(month, day, hour, minute: minute);
}

class _DebugEntry {
  const _DebugEntry({
    required this.id,
    required this.type,
    required this.debitAccountId,
    required this.creditAccountId,
    required this.amount,
    required this.occurredAt,
    this.memo,
    this.tagIds = const [],
  });

  final String id;
  final EntryType type;
  final String debitAccountId;
  final String creditAccountId;
  final double amount;
  final String? memo;
  final String occurredAt;
  final List<String> tagIds;
}

class _CashExpenseSpec {
  const _CashExpenseSpec(
    this.accountId,
    this.amount,
    this.memo, {
    this.tagIds = const [],
  });

  final String accountId;
  final double amount;
  final String memo;
  final List<String> tagIds;
}
