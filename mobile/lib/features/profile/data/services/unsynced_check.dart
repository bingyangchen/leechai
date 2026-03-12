import 'package:mobile/core/database/app_database.dart';

class UnsyncedCheck {
  UnsyncedCheck._();

  static Future<bool> hasUnsyncedData() async {
    final db = await AppDatabase.database;
    final entryRows = await db.query(
      'entry',
      columns: ['id'],
      where: 'synced = 0',
      limit: 1,
    );
    if (entryRows.isNotEmpty) return true;
    final accountRows = await db.query(
      'account',
      columns: ['id'],
      where: 'synced = 0',
      limit: 1,
    );
    if (accountRows.isNotEmpty) return true;
    final achievementRows = await db.query(
      'achievements',
      columns: ['id'],
      where: 'synced = 0',
      limit: 1,
    );
    return achievementRows.isNotEmpty;
  }
}
