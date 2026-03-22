import 'package:flutter/material.dart';
import 'package:mobile/features/account/data/repositories/account.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/budget/data/repositories/budget.dart';
import 'package:mobile/features/statistics/data/services/statistics.dart';

class MonthBudgetSnapshot {
  const MonthBudgetSnapshot({
    required this.year,
    required this.month,
    required this.spentExpense,
    this.totalBudget,
    required this.remainingDaysInMonth,
    required this.categoryBudgetRows,
  });

  final int year;
  final int month;
  final double spentExpense;
  final double? totalBudget;
  final int remainingDaysInMonth;
  final List<CategoryBudgetRow> categoryBudgetRows;

  double? get remainingAmount {
    final cap = totalBudget;
    if (cap == null) return null;
    return cap - spentExpense;
  }

  double? get dailySuggested {
    final cap = totalBudget;
    if (cap == null) return null;
    if (remainingDaysInMonth <= 0) return null;
    return (cap - spentExpense) / remainingDaysInMonth;
  }

  double get spentRatio {
    final cap = totalBudget;
    if (cap == null || cap <= 0) return 0;
    return spentExpense / cap;
  }
}

class CategoryBudgetRow {
  const CategoryBudgetRow({
    required this.subType,
    required this.icon,
    required this.budgetAmount,
    required this.spentAmount,
  });

  final String subType;
  final IconData icon;
  final double budgetAmount;
  final double spentAmount;

  double get ratio => budgetAmount <= 0 ? 0 : spentAmount / budgetAmount;
}

class BudgetService {
  BudgetService._();

  static int remainingDaysInMonthFromNow(DateTime now) {
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return lastDay - now.day + 1;
  }

  static Future<double> averageExpenseLastThreeFullMonths(DateTime anchor) async {
    double sum = 0;
    var count = 0;
    for (var i = 1; i <= 3; i++) {
      final m = DateTime(anchor.year, anchor.month - i, 1);
      final start = DateTime(m.year, m.month, 1);
      final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59, 999);
      final totals = await StatisticsService.getRangeTotals(start, end);
      sum += totals.totalExpense;
      count++;
    }
    if (count == 0) return 0;
    return sum / count;
  }

  static Future<double?> totalBudgetForPreviousMonth(DateTime anchor) async {
    final prev = DateTime(anchor.year, anchor.month - 1, 1);
    return BudgetRepository.getTotalForMonth(prev.year, prev.month);
  }

  static Future<MonthBudgetSnapshot> loadSnapshotForMonth(
    int year,
    int month,
    DateTime now,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    final totals = await StatisticsService.getRangeTotals(start, end);
    final spent = totals.totalExpense;
    final totalBudget = await BudgetRepository.getTotalForMonth(year, month);
    final categoryBudgets = await BudgetRepository.getCategoryBudgetsForMonth(
      year,
      month,
    );

    final breakdown = await StatisticsService.getCategoryBreakdown(start, end, true);
    final spentBySubType = {for (final item in breakdown) item.subType: item.amount};

    final accounts = await AccountRepository.getByType(AccountType.expense.name);
    final rows = <CategoryBudgetRow>[];
    for (final entry in categoryBudgets.entries) {
      final subType = entry.key;
      final cap = entry.value;
      var resolvedIcon = Icons.category;
      for (final a in accounts) {
        if (a.subType == subType) {
          resolvedIcon = a.displayIcon;
          break;
        }
      }
      rows.add(
        CategoryBudgetRow(
          subType: subType,
          icon: resolvedIcon,
          budgetAmount: cap,
          spentAmount: spentBySubType[subType] ?? 0,
        ),
      );
    }
    rows.sort((a, b) => b.spentAmount.compareTo(a.spentAmount));

    final sameMonth = now.year == year && now.month == month;
    final remainingDays = sameMonth ? remainingDaysInMonthFromNow(now) : 0;

    return MonthBudgetSnapshot(
      year: year,
      month: month,
      spentExpense: spent,
      totalBudget: totalBudget,
      remainingDaysInMonth: remainingDays,
      categoryBudgetRows: rows,
    );
  }

  static Future<Map<String, double>> expenseAmountsBySubTypeForMonth(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    final breakdown = await StatisticsService.getCategoryBreakdown(start, end, true);
    return {for (final item in breakdown) item.subType: item.amount};
  }
}
