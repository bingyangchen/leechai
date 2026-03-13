import 'dart:async';
import 'dart:developer' as developer;

import 'package:mobile/features/account/data/repositories/account.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart';
import 'package:mobile/features/profile/data/repositories/achievement.dart';
import 'package:mobile/features/profile/domain/achievement_definitions.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';

class AchievementService {
  AchievementService._();

  static final AchievementService instance = AchievementService._();

  final _controller = StreamController<AchievementItem>.broadcast();
  Stream<AchievementItem> get onUnlocked => _controller.stream;

  final List<AchievementItem> _pendingUnlocks = [];

  List<AchievementItem> drainPending() {
    final list = _pendingUnlocks.toList();
    _pendingUnlocks.clear();
    return list;
  }

  Future<void> notifyUnlocked(String achievementId) async {
    try {
      final row = await AchievementRepository.getByAchievementId(achievementId);
      if (row == null ||
          row['unlocked_at'] == null ||
          (row['is_notified'] as int? ?? 0) == 1) {
        return;
      }
      final achievements = achievementsFromRepositoryRows([
        row,
      ], achievementDefinitions);
      final item = achievements.where((a) => a.id == achievementId).firstOrNull;
      if (item == null || !item.isUnlocked) return;
      await Future.delayed(const Duration(milliseconds: 350));
      _controller.add(item);
      _pendingUnlocks.add(item);
      await AchievementRepository.markAsNotified([achievementId]);
    } catch (error, stackTrace) {
      developer.log('notifyUnlocked failed', error: error, stackTrace: stackTrace);
    }
  }

  static bool _isOneTimeAndAlreadyUnlocked(
    Map<String, Object?>? row,
    AchievementId id,
  ) =>
      row != null &&
      row['unlocked_at'] != null &&
      id.definition.repeatType == AchievementRepeatType.oneTime;

  static Future<void> evaluateAfterEntryInserted({
    required String type,
    required DateTime occurredAt,
    required List<String> tagIds,
    required double amount,
  }) async {
    try {
      final now = DateTime.now();
      final occurredLocal = occurredAt.toLocal();
      final today = DateTime(now.year, now.month, now.day);
      final occurredDate = DateTime(
        occurredLocal.year,
        occurredLocal.month,
        occurredLocal.day,
      );
      final isBackfill = occurredDate.isBefore(today);
      final totalCount = await EntryRepository.getCount();

      await _updateCountAchievements(totalCount);

      await _updateBackfillStreak(isBackfill);

      await _updateMonthlyPerfect(occurredAt);

      if (_isWeekend(occurredLocal)) await _updateFourWeekendsStreak();

      await _updateStreakAchievements();

      if (type == 'income') await _unlockFirstIncome();

      await _unlockOneYear();

      if (tagIds.isNotEmpty) await _unlockFirstCustomTag();

      final hour = now.toLocal().hour;
      if (hour >= 2 && hour <= 3) await _unlockNightOwl();
      if (_amountContains777(amount)) await _unlockLucky777();
    } catch (error, stackTrace) {
      developer.log(
        'evaluateAfterEntryInserted failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> evaluateAfterAccountInserted() async {
    try {
      final target = AchievementId.secondAccount.definition.target;
      final accounts = await AccountRepository.getBalanceAccounts();
      if (accounts.length >= target) {
        final row = await AchievementRepository.getByAchievementId(
          AchievementId.secondAccount.key,
        );
        if (row != null &&
            !_isOneTimeAndAlreadyUnlocked(row, AchievementId.secondAccount)) {
          await AchievementRepository.updateProgress(
            AchievementId.secondAccount.key,
            progress: accounts.length,
            unlockedAt: DateTime.now(),
          );
          await AchievementService.instance.notifyUnlocked(
            AchievementId.secondAccount.key,
          );
        }
      }
    } catch (error, stackTrace) {
      developer.log(
        'evaluateAfterAccountInserted failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _updateCountAchievements(int totalCount) async {
    for (final id in [
      AchievementId.firstEntry,
      AchievementId.hundredEntries,
      AchievementId.thousandEntries,
    ]) {
      final row = await AchievementRepository.getByAchievementId(id.key);
      if (row == null) continue;
      final target = id.definition.target;
      final progress = totalCount.clamp(0, target);
      final alreadyUnlocked = row['unlocked_at'] != null;
      final justUnlocked = !alreadyUnlocked && progress >= target;
      await AchievementRepository.updateProgress(
        id.key,
        progress: progress,
        unlockedAt: justUnlocked ? DateTime.now() : null,
      );
      if (justUnlocked) {
        await AchievementService.instance.notifyUnlocked(id.key);
      }
    }
  }

  static Future<void> _updateBackfillStreak(bool isBackfill) async {
    final row = await AchievementRepository.getByAchievementId(
      AchievementId.backfillStreak3.key,
    );
    if (row == null) return;
    final current = isBackfill ? ((row['progress'] as int?) ?? 0) + 1 : 0;
    final target = AchievementId.backfillStreak3.definition.target;
    final alreadyUnlocked = row['unlocked_at'] != null;
    final justUnlocked = !alreadyUnlocked && current >= target;
    await AchievementRepository.updateProgress(
      AchievementId.backfillStreak3.key,
      progress: current.clamp(0, target),
      unlockedAt: justUnlocked ? DateTime.now() : null,
    );
    if (justUnlocked) {
      await AchievementService.instance.notifyUnlocked(
        AchievementId.backfillStreak3.key,
      );
    }
  }

  static bool _isWeekend(DateTime date) {
    final w = date.weekday;
    return w == DateTime.saturday || w == DateTime.sunday;
  }

  static Future<void> _updateMonthlyPerfect(DateTime occurredAt) async {
    final month = DateTime(occurredAt.year, occurredAt.month);
    final entries = await EntryRepository.getByMonth(month);
    final distinctDays = entries
        .map((e) {
          final v = e['occurred_at'];
          if (v == null) return null;
          final dt = DateTime.parse(v as String).toLocal();
          return DateTime(dt.year, dt.month, dt.day);
        })
        .whereType<DateTime>()
        .toSet()
        .length;
    final lastDay = DateTime(occurredAt.year, occurredAt.month + 1, 0).day;
    final target = lastDay;
    final progress = distinctDays.clamp(0, target);

    final row = await AchievementRepository.getByAchievementId(
      AchievementId.monthlyPerfect.key,
    );
    if (row == null) return;
    final periodKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final previousProgress = (row['progress'] as int?) ?? 0;
    final completedCount = (row['completed_count'] as int?) ?? 0;
    final alreadyUnlocked = row['unlocked_at'] != null;

    var newCompletedCount = completedCount;
    DateTime? unlockAt;
    if (progress >= target && previousProgress < target) {
      newCompletedCount = completedCount + 1;
      unlockAt = alreadyUnlocked ? null : DateTime.now();
    }

    await AchievementRepository.updateProgress(
      AchievementId.monthlyPerfect.key,
      progress: progress,
      progressPeriod: periodKey,
      completedCount: newCompletedCount,
      unlockedAt: unlockAt,
    );
    if (unlockAt != null) {
      await AchievementService.instance.notifyUnlocked(
        AchievementId.monthlyPerfect.key,
      );
    }
  }

  static Future<void> _updateFourWeekendsStreak() async {
    final now = DateTime.now();
    final weekends = <DateTime>[];
    var d = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 4; i++) {
      while (d.weekday != DateTime.saturday) {
        d = d.subtract(const Duration(days: 1));
      }
      weekends.add(d);
      d = d.subtract(const Duration(days: 1));
    }
    var allHaveEntry = true;
    for (final sat in weekends) {
      final sun = sat.add(const Duration(days: 1));
      final start = DateTime(sat.year, sat.month, sat.day);
      final end = DateTime(sun.year, sun.month, sun.day, 23, 59, 59, 999);
      final entries = await EntryRepository.getByDateRange(start, end);
      if (entries.isEmpty) {
        allHaveEntry = false;
        break;
      }
    }
    if (!allHaveEntry) return;
    final row = await AchievementRepository.getByAchievementId(
      AchievementId.fourWeekendsStreak.key,
    );
    if (row == null ||
        _isOneTimeAndAlreadyUnlocked(row, AchievementId.fourWeekendsStreak)) {
      return;
    }
    await AchievementRepository.updateProgress(
      AchievementId.fourWeekendsStreak.key,
      progress: AchievementId.fourWeekendsStreak.definition.target,
      unlockedAt: DateTime.now(),
    );
    await AchievementService.instance.notifyUnlocked(
      AchievementId.fourWeekendsStreak.key,
    );
  }

  static Future<int> _computeConsecutiveStreak() async {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final start = end.subtract(const Duration(days: 100));
    final entries = await EntryRepository.getByDateRange(start, end);
    final dates =
        entries
            .map((e) {
              final v = e['occurred_at'];
              if (v == null) return null;
              final dt = DateTime.parse(v as String).toLocal();
              return DateTime(dt.year, dt.month, dt.day);
            })
            .whereType<DateTime>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    if (dates.isEmpty) return 0;
    final today = DateTime(now.year, now.month, now.day);
    if (dates.first != today &&
        dates.first != today.subtract(const Duration(days: 1))) {
      return 0;
    }
    var streak = 0;
    var expect = today;
    for (final d in dates) {
      if (d == expect) {
        streak++;
        expect = expect.subtract(const Duration(days: 1));
      } else if (d.isBefore(expect)) {
        break;
      }
    }
    return streak;
  }

  static Future<void> _updateStreakAchievements() async {
    final streak = await _computeConsecutiveStreak();
    for (final id in [
      AchievementId.streak7Days,
      AchievementId.streak30Days,
      AchievementId.streak100Days,
    ]) {
      final row = await AchievementRepository.getByAchievementId(id.key);
      if (row == null) continue;
      final target = id.definition.target;
      final progress = streak.clamp(0, target);
      final alreadyUnlocked = row['unlocked_at'] != null;
      final justUnlocked = !alreadyUnlocked && progress >= target;
      await AchievementRepository.updateProgress(
        id.key,
        progress: progress,
        unlockedAt: justUnlocked ? DateTime.now() : null,
      );
      if (justUnlocked) {
        await AchievementService.instance.notifyUnlocked(id.key);
      }
    }
  }

  static Future<void> evaluatePositiveCashflowForPreviousMonth() async {
    try {
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1);
      final periodKey =
          '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}';
      final row = await AchievementRepository.getByAchievementId(
        AchievementId.positiveCashflow.key,
      );
      if (row == null) return;
      if ((row['progress_period'] as String?) == periodKey) return;
      final entries = await EntryRepository.getByMonth(previousMonth);
      var income = 0.0;
      var expense = 0.0;
      for (final e in entries) {
        final typeStr = e['type'] as String? ?? 'expense';
        final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
        if (typeStr == 'income') {
          income += amount;
        } else if (typeStr == 'expense') {
          expense += amount;
        }
      }
      if (income <= expense) return;
      final completedCount = (row['completed_count'] as int?) ?? 0;
      final alreadyUnlocked = row['unlocked_at'] != null;
      final justUnlocked = !alreadyUnlocked;
      await AchievementRepository.updateProgress(
        AchievementId.positiveCashflow.key,
        progress: 1,
        progressPeriod: periodKey,
        completedCount: completedCount + 1,
        unlockedAt: justUnlocked ? DateTime.now() : null,
      );
      if (justUnlocked) {
        await AchievementService.instance.notifyUnlocked(
          AchievementId.positiveCashflow.key,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'evaluatePositiveCashflowForPreviousMonth failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _unlockFirstIncome() async {
    final row = await AchievementRepository.getByAchievementId(
      AchievementId.firstIncome.key,
    );
    if (row == null || _isOneTimeAndAlreadyUnlocked(row, AchievementId.firstIncome)) {
      return;
    }
    await AchievementRepository.updateProgress(
      AchievementId.firstIncome.key,
      progress: 1,
      unlockedAt: DateTime.now(),
    );
    await AchievementService.instance.notifyUnlocked(AchievementId.firstIncome.key);
  }

  static Future<void> _unlockOneYear() async {
    final earliest = await EntryRepository.getEarliestCreatedAt();
    if (earliest == null) return;
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    if (earliest.isAfter(oneYearAgo)) return;
    final row = await AchievementRepository.getByAchievementId(
      AchievementId.oneYear.key,
    );
    if (row == null || _isOneTimeAndAlreadyUnlocked(row, AchievementId.oneYear)) return;
    await AchievementRepository.updateProgress(
      AchievementId.oneYear.key,
      progress: 1,
      unlockedAt: DateTime.now(),
    );
    await AchievementService.instance.notifyUnlocked(AchievementId.oneYear.key);
  }

  static Future<void> _unlockFirstCustomTag() async {
    final row = await AchievementRepository.getByAchievementId(
      AchievementId.firstCustomTag.key,
    );
    if (row == null ||
        _isOneTimeAndAlreadyUnlocked(row, AchievementId.firstCustomTag)) {
      return;
    }
    await AchievementRepository.updateProgress(
      AchievementId.firstCustomTag.key,
      progress: 1,
      unlockedAt: DateTime.now(),
    );
    await AchievementService.instance.notifyUnlocked(AchievementId.firstCustomTag.key);
  }

  static Future<void> _unlockNightOwl() async {
    final row = await AchievementRepository.getByAchievementId(
      AchievementId.nightOwl.key,
    );
    if (row == null || _isOneTimeAndAlreadyUnlocked(row, AchievementId.nightOwl)) {
      return;
    }
    await AchievementRepository.updateProgress(
      AchievementId.nightOwl.key,
      progress: 1,
      unlockedAt: DateTime.now(),
    );
    await AchievementService.instance.notifyUnlocked(AchievementId.nightOwl.key);
  }

  static bool _amountContains777(double amount) {
    final s = amount.toStringAsFixed(2);
    return s.contains('777');
  }

  static Future<void> _unlockLucky777() async {
    final row = await AchievementRepository.getByAchievementId(
      AchievementId.lucky777.key,
    );
    if (row == null || _isOneTimeAndAlreadyUnlocked(row, AchievementId.lucky777)) {
      return;
    }
    await AchievementRepository.updateProgress(
      AchievementId.lucky777.key,
      progress: 1,
      unlockedAt: DateTime.now(),
    );
    await AchievementService.instance.notifyUnlocked(AchievementId.lucky777.key);
  }
}
