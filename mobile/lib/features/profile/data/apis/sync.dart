import 'dart:convert';

import 'package:mobile/core/network/api_client.dart';

class SyncPullResponse {
  const SyncPullResponse({required this.changes, required this.syncedAt});

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) {
    /* Expected JSON (snake_case columns, same as local DB):
    {
      "changes": {
        "entry": [{ "id": "uuid-1", "type": "expense", "debit_account_id": "a1", "credit_account_id": "a2", "amount": 100, "memo": null, "occurred_at": "2024-03-14T00:00:00", "created_at": "2024-03-14T00:00:00", "updated_at": "2024-03-14T00:00:00", "deleted_at": null, "synced": 1 }],
        "account": [{ "id": "uuid-2", "type": "asset", "sub_type": "cash", "name": "現金", "icon": "123", "initial_balance": 0, "last_used_at": "2024-03-14T00:00:00", "created_at": "2024-03-14T00:00:00", "updated_at": "2024-03-14T00:00:00", "deleted_at": null, "synced": 1 }],
        "tag": [{ "id": "uuid-3", "title": "飲食", "created_at": "2024-03-14T00:00:00", "updated_at": "2024-03-14T00:00:00", "deleted_at": null, "synced": 1 }],
        "entry_tag": [{ "entry_id": "uuid-1", "tag_id": "uuid-3", "updated_at": "2024-03-14T00:00:00", "deleted_at": null, "synced": 1 }],
        "achievement": [{ "id": "first_entry", "progress": 1, "target": 1, "unlocked_at": "2024-03-14T00:00:00", "completed_count": 0, "progress_period": null, "is_notified": 0, "created_at": "2024-03-14T00:00:00", "updated_at": "2024-03-14T00:00:00", "synced": 1 }]
      },
      "syncedAt": "2024-03-14T12:00:00Z"
    }
    */
    final rawChanges = json['changes'] as Map<String, dynamic>;
    final changes = <String, List<Map<String, dynamic>>>{};
    for (final entry in rawChanges.entries) {
      changes[entry.key] = (entry.value as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return SyncPullResponse(changes: changes, syncedAt: json['syncedAt'] as String);
  }

  final Map<String, List<Map<String, dynamic>>> changes;
  final String syncedAt;
}

class SyncPushResponse {
  const SyncPushResponse({required this.syncedAt});

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) {
    return SyncPushResponse(syncedAt: json['syncedAt'] as String);
  }

  final String syncedAt;
}

class SyncApi {
  SyncApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<SyncPullResponse> pull(String? lastSyncedAt) async {
    final queryParameters = lastSyncedAt != null
        ? <String, String>{'lastSyncedAt': lastSyncedAt}
        : null;
    final response = await _client.get('/sync/pull', queryParameters: queryParameters);
    if (response.statusCode == 200) {
      return SyncPullResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Sync pull failed: ${response.statusCode}');
  }

  Future<SyncPushResponse> push(Map<String, List<Map<String, dynamic>>> changes) async {
    final sanitizedChanges = <String, List<Map<String, dynamic>>>{};
    for (final entry in changes.entries) {
      sanitizedChanges[entry.key] = entry.value
          .map((row) => Map<String, dynamic>.from(row)..remove('synced'))
          .toList();
    }
    final response = await _client.post(
      '/sync/push',
      body: jsonEncode(sanitizedChanges),
    );
    if (response.statusCode == 200) {
      return SyncPushResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Sync push failed: ${response.statusCode}');
  }
}
