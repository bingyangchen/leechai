enum NetWorthRange { oneMonth, threeMonths, sixMonths, oneYear, all }

extension NetWorthRangeX on NetWorthRange {
  String get label {
    switch (this) {
      case NetWorthRange.oneMonth:
        return '1個月';
      case NetWorthRange.threeMonths:
        return '3個月';
      case NetWorthRange.sixMonths:
        return '6個月';
      case NetWorthRange.oneYear:
        return '1年';
      case NetWorthRange.all:
        return '全部';
    }
  }

  ({DateTime start, DateTime end}) get dateRange {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    DateTime start;
    switch (this) {
      case NetWorthRange.oneMonth:
        start = DateTime(now.year, now.month - 1, 1);
        break;
      case NetWorthRange.threeMonths:
        start = DateTime(now.year, now.month - 3, 1);
        break;
      case NetWorthRange.sixMonths:
        start = DateTime(now.year, now.month - 6, 1);
        break;
      case NetWorthRange.oneYear:
        start = DateTime(now.year - 1, now.month, 1);
        break;
      case NetWorthRange.all:
        start = DateTime(2020, 1, 1);
        break;
    }
    return (start: start, end: end);
  }
}
