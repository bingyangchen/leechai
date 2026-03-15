import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/auth/data/services/auth.dart';
import 'package:mobile/features/profile/data/apis/sync.dart';
import 'package:mobile/features/profile/data/repositories/cloud_sync.dart';
import 'package:sqflite/sqflite.dart';

enum CloudSyncStatus { synced, syncing, offline }

const List<({String table, List<String> primaryKey})> _syncedTables = [
  (table: 'entry', primaryKey: ['id']),
  (table: 'account', primaryKey: ['id']),
  (table: 'achievement', primaryKey: ['id']),
  (table: 'tag', primaryKey: ['id']),
  (table: 'entry_tag', primaryKey: ['entry_id', 'tag_id']),
];

class CloudSyncService {
  CloudSyncService._();

  static final CloudSyncService instance = CloudSyncService._();
  static const _periodicInterval = Duration(seconds: 30);
  final SyncApi _syncApi = SyncApi(client: ApiClient());
  final ValueNotifier<CloudSyncStatus> status = ValueNotifier(CloudSyncStatus.synced);

  ValueNotifier<DateTime?> get lastSyncAt => LastSyncRepository.lastSyncAt;

  VoidCallback? onSyncComplete;
  Timer? _periodicTimer;

  Future<void> ensureLoaded() async {
    await LastSyncRepository.ensureLoaded();
  }

  void startPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_periodicInterval, (_) {
      syncIfNeeded().catchError((_, stackTrace) {});
    });
  }

  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  Future<void> sync() async {
    if (status.value == CloudSyncStatus.syncing) return;
    status.value = CloudSyncStatus.syncing;
    try {
      final db = await AppDatabase.database;

      final pullResponse = await _syncApi.pull(
        LastSyncRepository.lastSyncAt.value?.toUtc().toIso8601String(),
      );

      await _mergePulledChanges(db, pullResponse.changes);
      String syncedAt = pullResponse.syncedAt;

      final unsynced = await _collectUnsyncedChanges(db);
      if (unsynced.isNotEmpty) {
        final pushResponse = await _syncApi.push(unsynced);
        syncedAt = pushResponse.syncedAt;
        await _markPushedAsSynced(db, unsynced);
      }

      await LastSyncRepository.save(DateTime.parse(syncedAt));
      status.value = CloudSyncStatus.synced;
      onSyncComplete?.call();
    } catch (_) {
      status.value = CloudSyncStatus.offline;
    }
  }

  Future<void> syncIfNeeded() async {
    if (!AuthService.instance.isLoggedIn) return;
    await sync();
  }

  Future<void> clearLastSyncAt() async {
    await LastSyncRepository.clear();
  }

  Future<void> _mergePulledChanges(
    Database db,
    Map<String, List<Map<String, dynamic>>> changes,
  ) async {
    for (final (:table, :primaryKey) in _syncedTables) {
      final remoteRows = changes[table];
      if (remoteRows == null || remoteRows.isEmpty) continue;

      final whereClause = primaryKey.map((col) => '$col = ?').join(' AND ');

      for (final remoteRow in remoteRows) {
        final whereArgs = primaryKey.map((col) => remoteRow[col]).toList();
        final locals = await db.query(table, where: whereClause, whereArgs: whereArgs);

        if (locals.isEmpty) {
          await db.insert(table, {
            ...remoteRow,
            'synced': 1,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        } else {
          final localUpdatedAt = locals.first['updated_at'] as String;
          final remoteUpdatedAt = remoteRow['updated_at'] as String;
          if (remoteUpdatedAt.compareTo(localUpdatedAt) > 0) {
            await db.update(
              table,
              {...remoteRow, 'synced': 1},
              where: whereClause,
              whereArgs: whereArgs,
            );
          }
        }
      }
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _collectUnsyncedChanges(
    Database db,
  ) async {
    final changes = <String, List<Map<String, dynamic>>>{};
    for (final (:table, primaryKey: _) in _syncedTables) {
      final rows = await db.query(table, where: 'synced = 0');
      if (rows.isNotEmpty) {
        changes[table] = rows;
      }
    }
    return changes;
  }

  Future<void> _markPushedAsSynced(
    Database db,
    Map<String, List<Map<String, dynamic>>> pushedChanges,
  ) async {
    for (final (:table, :primaryKey) in _syncedTables) {
      final rows = pushedChanges[table];
      if (rows == null || rows.isEmpty) continue;

      final whereClause = primaryKey.map((col) => '$col = ?').join(' AND ');
      final batch = db.batch();
      for (final row in rows) {
        final whereArgs = primaryKey.map((col) => row[col]).toList();
        batch.update(table, {'synced': 1}, where: whereClause, whereArgs: whereArgs);
      }
      await batch.commit(noResult: true);
    }
  }
}
