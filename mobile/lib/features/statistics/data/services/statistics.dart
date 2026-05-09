import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/data/services/account_balance.dart'
    show AccountBalanceService;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/statistics/domain/category_breakdown_item.dart';
import 'package:mobile/features/statistics/domain/net_worth_snapshot.dart';

class _NetWorthComputeInput {
  const _NetWorthComputeInput({
    required this.accounts,
    required this.entries,
    required this.start,
    required this.end,
  });

  final List<Account> accounts;
  final List<Map<String, Object?>> entries;
  final DateTime start;
  final DateTime end;
}

class StatisticsService {
  StatisticsService._();

  static Future<List<CategoryBreakdownItem>> getCategoryBreakdown(
    DateTime start,
    DateTime end,
    bool isExpense,
  ) async {
    final entries = await EntryRepository.getByOccurredAtDateRange(start, end);
    final allAccounts = <String, Account>{};
    for (final a in await AccountRepository.getAll()) {
      allAccounts[a.id] = a;
    }

    final targetType = isExpense ? EntryType.expense : EntryType.income;
    final categoryAccountIdKey = isExpense ? 'debit_account_id' : 'credit_account_id';
    final map = <String, ({double amount, IconData icon})>{};
    double total = 0;

    for (final e in entries) {
      final typeStr = e['type'] as String? ?? 'expense';
      final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
      if (type != targetType) continue;

      final catId = e[categoryAccountIdKey] as String? ?? '';
      final account = allAccounts[catId];
      final subType = account?.subType ?? '其他';
      final icon = account?.displayIcon ?? Icons.category;
      final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;

      total += amount;
      final existing = map[subType];
      if (existing != null) {
        map[subType] = (amount: existing.amount + amount, icon: icon);
      } else {
        map[subType] = (amount: amount, icon: icon);
      }
    }

    if (total <= 0) {
      return map.entries
          .map(
            (e) => CategoryBreakdownItem(
              subType: e.key,
              amount: e.value.amount,
              percent: 0,
              icon: e.value.icon,
            ),
          )
          .toList();
    }

    return map.entries
        .map(
          (e) => CategoryBreakdownItem(
            subType: e.key,
            amount: e.value.amount,
            percent: e.value.amount / total * 100,
            icon: e.value.icon,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  static Future<List<NetWorthSnapshot>> getNetWorthHistory(
    DateTime start,
    DateTime end,
  ) async {
    final accounts = await AccountRepository.getBalanceAccounts();
    final entries = await EntryRepository.getUpTo(end);
    return compute(
      _computeNetWorthHistory,
      _NetWorthComputeInput(
        accounts: accounts,
        entries: entries,
        start: start,
        end: end,
      ),
    );
  }

  static List<NetWorthSnapshot> _computeNetWorthHistory(_NetWorthComputeInput input) {
    final result = <NetWorthSnapshot>[];
    var current = DateTime(input.start.year, input.start.month, input.start.day);

    while (!current.isAfter(DateTime(input.end.year, input.end.month, input.end.day))) {
      final asOf = DateTime(current.year, current.month, current.day, 23, 59, 59, 999);
      double totalAssets = 0;
      double totalLiabilities = 0;

      for (final a in input.accounts) {
        final b = AccountBalanceService.balanceAsOf(a, input.entries, asOf);
        if (a.type == AccountType.asset) {
          totalAssets += b;
        } else {
          totalLiabilities += b;
        }
      }

      result.add(
        NetWorthSnapshot(
          date: current,
          netWorth: totalAssets - totalLiabilities,
          totalAssets: totalAssets,
          totalLiabilities: totalLiabilities,
        ),
      );
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  static Future<List<({DateTime month, double amount})>> getCategoryMonthlyTotals(
    String subType,
    bool isExpense,
    DateTime rangeEnd,
  ) async {
    final rangeStart = DateTime(rangeEnd.year, rangeEnd.month - 11, 1);
    final endOfRange = DateTime(rangeEnd.year, rangeEnd.month + 1, 0, 23, 59, 59, 999);
    final entries = await EntryRepository.getByOccurredAtDateRange(
      rangeStart,
      endOfRange,
    );
    final allAccounts = <String, Account>{};
    for (final a in await AccountRepository.getAll()) {
      allAccounts[a.id] = a;
    }

    final targetType = isExpense ? EntryType.expense : EntryType.income;
    final categoryKey = isExpense ? 'debit_account_id' : 'credit_account_id';
    final categoryAccountIds = allAccounts.values
        .where(
          (a) =>
              a.type == (isExpense ? AccountType.expense : AccountType.income) &&
              a.subType == subType,
        )
        .map((a) => a.id)
        .toSet();

    final monthly = <int, double>{};
    for (var i = 0; i < 12; i++) {
      final m = DateTime(rangeEnd.year, rangeEnd.month - 11 + i, 1);
      monthly[m.millisecondsSinceEpoch] = 0;
    }

    for (final e in entries) {
      final typeStr = e['type'] as String? ?? 'expense';
      final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
      if (type != targetType) continue;
      final catId = e[categoryKey] as String? ?? '';
      if (!categoryAccountIds.contains(catId)) continue;

      final occurredAt = e['occurred_at'] as String?;
      if (occurredAt == null) continue;
      DateTime t;
      try {
        t = DateTime.parse(occurredAt).toLocal();
      } catch (_) {
        continue;
      }
      final monthKey = DateTime(t.year, t.month, 1);
      final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
      monthly[monthKey.millisecondsSinceEpoch] =
          (monthly[monthKey.millisecondsSinceEpoch] ?? 0) + amount;
    }

    return [
      for (var i = 0; i < 12; i++)
        (
          month: DateTime(rangeEnd.year, rangeEnd.month - 11 + i, 1),
          amount:
              monthly[DateTime(
                rangeEnd.year,
                rangeEnd.month - 11 + i,
                1,
              ).millisecondsSinceEpoch] ??
              0,
        ),
    ];
  }

  static Future<List<({DateTime month, double amount})>> getEntryTypeMonthlyTotals(
    bool isExpense,
    DateTime rangeEnd,
  ) async {
    final rangeStart = DateTime(rangeEnd.year, rangeEnd.month - 11, 1);
    final endOfRange = DateTime(rangeEnd.year, rangeEnd.month + 1, 0, 23, 59, 59, 999);
    final entries = await EntryRepository.getByOccurredAtDateRange(
      rangeStart,
      endOfRange,
    );
    final targetType = isExpense ? EntryType.expense : EntryType.income;

    final monthly = <int, double>{};
    for (var i = 0; i < 12; i++) {
      final month = DateTime(rangeEnd.year, rangeEnd.month - 11 + i, 1);
      monthly[month.millisecondsSinceEpoch] = 0;
    }

    for (final entry in entries) {
      final typeStr = entry['type'] as String? ?? 'expense';
      final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
      if (type != targetType) continue;

      final occurredAt = entry['occurred_at'] as String?;
      if (occurredAt == null) continue;
      DateTime time;
      try {
        time = DateTime.parse(occurredAt).toLocal();
      } catch (_) {
        continue;
      }
      final monthKey = DateTime(time.year, time.month, 1);
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
      monthly[monthKey.millisecondsSinceEpoch] =
          (monthly[monthKey.millisecondsSinceEpoch] ?? 0) + amount;
    }

    return [
      for (var i = 0; i < 12; i++)
        (
          month: DateTime(rangeEnd.year, rangeEnd.month - 11 + i, 1),
          amount:
              monthly[DateTime(
                rangeEnd.year,
                rangeEnd.month - 11 + i,
                1,
              ).millisecondsSinceEpoch] ??
              0,
        ),
    ];
  }

  static Future<({double totalExpense, double totalIncome})> getRangeTotals(
    DateTime start,
    DateTime end,
  ) async {
    final entries = await EntryRepository.getByOccurredAtDateRange(start, end);
    double expense = 0;
    double income = 0;
    for (final e in entries) {
      final typeStr = e['type'] as String? ?? 'expense';
      final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
      final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
      if (type == EntryType.expense) {
        expense += amount;
      } else if (type == EntryType.income) {
        income += amount;
      }
    }
    return (totalExpense: expense, totalIncome: income);
  }
}
