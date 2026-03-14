import 'package:flutter/foundation.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/auth/data/services/auth.dart';
import 'package:mobile/features/profile/data/repositories/last_sync.dart';

enum CloudSyncStatus { synced, syncing, offline }

const List<({String table, String column})> _syncedTables = [
  (table: 'entry', column: 'id'),
  (table: 'account', column: 'id'),
  (table: 'achievements', column: 'id'),
  (table: 'tag', column: 'id'),
  (table: 'entry_tag', column: 'entry_id'),
];

class CloudSyncService {
  CloudSyncService._();

  static final CloudSyncService instance = CloudSyncService._();

  final ValueNotifier<CloudSyncStatus> status = ValueNotifier(CloudSyncStatus.synced);
  ValueNotifier<DateTime?> get lastSyncAt => LastSyncRepository.lastSyncAt;

  VoidCallback? onSyncComplete;

  bool _isSyncing = false;

  Future<void> ensureLoaded() async {
    await LastSyncRepository.ensureLoaded();
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    status.value = CloudSyncStatus.syncing;
    try {
      // TODO: Implement actual sync logic
      await Future<void>.delayed(const Duration(seconds: 2));

      final now = DateTime.now();
      await LastSyncRepository.save(now);
      status.value = CloudSyncStatus.synced;
      onSyncComplete?.call();
    } catch (_) {
      status.value = CloudSyncStatus.offline;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> clearLastSyncAt() async {
    await LastSyncRepository.clear();
  }

  Future<bool> hasUnsyncedData() async {
    final db = await AppDatabase.database;
    for (final (:table, :column) in _syncedTables) {
      final rows = await db.query(
        table,
        columns: [column],
        where: 'synced = 0',
        limit: 1,
      );
      if (rows.isNotEmpty) return true;
    }
    return false;
  }

  Future<void> syncIfNeeded() async {
    if (!AuthService.instance.isLoggedIn) return;
    if (!await hasUnsyncedData()) return;
    await sync();
  }
}
