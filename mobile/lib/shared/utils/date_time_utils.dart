String formatDate(DateTime dateTime) {
  final d = dateTime;
  final monthStr = d.month.toString().padLeft(2, '0');
  final dayStr = d.day.toString().padLeft(2, '0');
  final now = DateTime.now();
  return d.year != now.year ? '${d.year}/$monthStr/$dayStr' : '$monthStr/$dayStr';
}

String formatDateTime(DateTime dateTime) {
  final d = dateTime;
  final h24 = d.hour;
  final hour12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
  final ampm = h24 < 12 ? 'AM' : 'PM';
  final monthStr = d.month.toString().padLeft(2, '0');
  final dayStr = d.day.toString().padLeft(2, '0');
  final timeStr =
      '${hour12.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  final now = DateTime.now();
  if (d.year != now.year) return '${d.year}/$monthStr/$dayStr $timeStr';
  return '$monthStr/$dayStr $timeStr';
}
