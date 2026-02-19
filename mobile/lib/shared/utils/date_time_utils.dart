/// Formats [dateTime] as a short, human-readable string.
///
/// - Same year: "M/d HH:mm AM/PM" (e.g. 2/19 03:45 PM)
/// - Different year: "y/M/d HH:mm AM/PM" (e.g. 2024/12/31 09:00 AM)
String formatDateTimeShort(DateTime dateTime) {
  final d = dateTime;
  final h24 = d.hour;
  final hour12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
  final ampm = h24 < 12 ? 'AM' : 'PM';
  final timeStr =
      '${hour12.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  final now = DateTime.now();
  if (d.year != now.year) {
    return '${d.year}/${d.month}/${d.day} $timeStr';
  }
  return '${d.month}/${d.day} $timeStr';
}
