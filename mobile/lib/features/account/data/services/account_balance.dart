import 'package:mobile/features/account/data/repositories/account.dart'
    show AccountRepository;
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;

class AccountBalanceService {
  AccountBalanceService._();

  static Future<Map<String, double>> getBalances() async {
    final accounts = await AccountRepository.getBalanceAccounts();
    final entries = await EntryRepository.getAll();
    final map = <String, double>{};
    for (final a in accounts) {
      map[a.id] = _balanceForAccount(a, entries);
    }
    return map;
  }

  static double _balanceForAccount(
    Account account,
    List<Map<String, Object?>> entries,
  ) {
    double balance = account.initialBalance;
    for (final e in entries) {
      final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
      final debitId = e['debit_account_id'] as String? ?? '';
      final creditId = e['credit_account_id'] as String? ?? '';
      if (account.id == debitId) {
        if (account.type == AccountType.asset) {
          balance += amount;
        } else {
          balance -= amount;
        }
      }
      if (account.id == creditId) {
        if (account.type == AccountType.asset) {
          balance -= amount;
        } else {
          balance += amount;
        }
      }
    }
    return balance;
  }

  static Future<List<double>> getNetWorthSparkline() async {
    final accounts = await AccountRepository.getBalanceAccounts();
    final entries = await EntryRepository.getAll();
    final now = DateTime.now();
    final points = <double>[];
    for (var i = 5; i >= 0; i--) {
      final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59, 999);
      if (monthEnd.isAfter(now)) continue;
      double net = 0;
      for (final a in accounts) {
        final b = _balanceAsOf(a, entries, monthEnd);
        net += b;
      }
      points.add(net);
    }
    while (points.length < 6) {
      points.insert(0, 0.0);
    }
    return points.length > 6 ? points.sublist(points.length - 6) : points;
  }

  static double _balanceAsOf(
    Account account,
    List<Map<String, Object?>> entries,
    DateTime asOf,
  ) {
    double balance = account.initialBalance;
    for (final e in entries) {
      final occurredAt = e['occurred_at'] as String?;
      if (occurredAt == null) continue;
      DateTime t;
      try {
        t = DateTime.parse(occurredAt).toLocal();
      } catch (_) {
        continue;
      }
      if (t.isAfter(asOf)) continue;
      final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
      final debitId = e['debit_account_id'] as String? ?? '';
      final creditId = e['credit_account_id'] as String? ?? '';
      if (account.id == debitId) {
        if (account.type == AccountType.asset) {
          balance += amount;
        } else {
          balance -= amount;
        }
      }
      if (account.id == creditId) {
        if (account.type == AccountType.asset) {
          balance -= amount;
        } else {
          balance += amount;
        }
      }
    }
    return balance;
  }
}
