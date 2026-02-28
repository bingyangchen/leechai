import 'package:mobile/features/entry/domain/entry_type.dart';

Map<DateTime, List<Map<String, Object?>>> groupEntriesByDate(
  List<Map<String, Object?>> entries,
) {
  final map = <DateTime, List<Map<String, Object?>>>{};
  for (final e in entries) {
    final occurredAt = e['occurred_at'] as String? ?? '';
    DateTime date;
    try {
      date = DateTime.parse(occurredAt).toLocal();
    } catch (_) {
      continue;
    }
    final day = DateTime(date.year, date.month, date.day);
    map.putIfAbsent(day, () => []).add(e);
  }
  final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
  return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, map[k]!)));
}

double dayExpense(List<Map<String, Object?>> dayEntries) {
  double sum = 0;
  for (final e in dayEntries) {
    final typeStr = e['type'] as String? ?? 'expense';
    final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
    if (type == EntryType.expense) sum += (e['amount'] as num?)?.toDouble() ?? 0.0;
  }
  return sum;
}

double dayIncome(List<Map<String, Object?>> dayEntries) {
  double sum = 0;
  for (final e in dayEntries) {
    final typeStr = e['type'] as String? ?? 'expense';
    final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
    if (type == EntryType.income) sum += (e['amount'] as num?)?.toDouble() ?? 0.0;
  }
  return sum;
}
