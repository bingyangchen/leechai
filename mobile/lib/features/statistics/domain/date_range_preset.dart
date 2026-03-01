enum DateRangePreset {
  thisMonth,
  lastQuarter,
  last6Months,
  last12Months,
  thisYear,
  custom,
}

extension DateRangePresetX on DateRangePreset {
  String get label {
    switch (this) {
      case DateRangePreset.thisMonth:
        return '本月';
      case DateRangePreset.lastQuarter:
        return '近一季';
      case DateRangePreset.last6Months:
        return '近半年';
      case DateRangePreset.last12Months:
        return '近一年';
      case DateRangePreset.thisYear:
        return '今年';
      case DateRangePreset.custom:
        return '自訂';
    }
  }
}

class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  static DateRange forPreset(DateRangePreset preset, DateTime anchor) {
    final now = anchor;
    switch (preset) {
      case DateRangePreset.thisMonth:
        return DateRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        );
      case DateRangePreset.lastQuarter:
        return DateRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        );
      case DateRangePreset.last6Months:
        return DateRange(
          start: DateTime(now.year, now.month - 5, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        );
      case DateRangePreset.last12Months:
        return DateRange(
          start: DateTime(now.year, now.month - 11, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        );
      case DateRangePreset.thisYear:
        return DateRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        );
      case DateRangePreset.custom:
        return DateRange(start: now, end: now);
    }
  }

  String toRangeLabel() {
    if (start.year == end.year && start.month == end.month) {
      return '${start.year} 年 ${start.month.toString().padLeft(2, '0')} 月';
    }
    return '${start.year} 年 ${start.month.toString().padLeft(2, '0')} 月 - ${end.year} 年 ${end.month.toString().padLeft(2, '0')} 月';
  }

  String toShortLabel([DateRangePreset? preset]) {
    if (preset != null && preset != DateRangePreset.custom) {
      return preset.label;
    }
    return toRangeLabel();
  }

  bool containsMonth(DateTime month) {
    final m = DateTime(month.year, month.month, 1);
    final s = DateTime(start.year, start.month, 1);
    final e = DateTime(end.year, end.month, 1);
    return !m.isBefore(s) && !m.isAfter(e);
  }
}
