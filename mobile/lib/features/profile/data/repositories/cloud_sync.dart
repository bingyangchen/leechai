import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyLastSyncAt = 'cloud_sync_last_sync_at';

class LastSyncRepository {
  LastSyncRepository._();

  static final ValueNotifier<DateTime?> lastSyncAt = ValueNotifier(null);
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    lastSyncAt.value = await _loadFromPrefs();
    _loaded = true;
  }

  static Future<void> save(DateTime dateTime) async {
    await _persist(dateTime);
    lastSyncAt.value = dateTime;
  }

  static Future<void> clear() async {
    await _clearPrefs();
    lastSyncAt.value = null;
  }

  static Future<DateTime?> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyLastSyncAt);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  static Future<void> _persist(DateTime dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSyncAt, dateTime.toUtc().toIso8601String());
  }

  static Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastSyncAt);
  }
}
