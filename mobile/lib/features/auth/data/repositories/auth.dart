import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyUserId = 'auth_user_id';
const String _keyDisplayName = 'auth_display_name';
const String _keyEmail = 'auth_email';
const String _keyAvatarUrl = 'auth_avatar_url';
const String _keyLastLinkedUserId = 'auth_last_linked_user_id';

class AuthRepository {
  AuthRepository._();

  static Future<AuthState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    if (userId == null || userId.isEmpty) return null;
    return AuthState(
      userId: userId,
      displayName: prefs.getString(_keyDisplayName) ?? '',
      email: prefs.getString(_keyEmail) ?? '',
      avatarUrl: prefs.getString(_keyAvatarUrl),
    );
  }

  static Future<void> save(AuthState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, state.userId);
    await prefs.setString(_keyDisplayName, state.displayName);
    await prefs.setString(_keyEmail, state.email);
    if (state.avatarUrl != null) {
      await prefs.setString(_keyAvatarUrl, state.avatarUrl!);
    } else {
      await prefs.remove(_keyAvatarUrl);
    }
    await prefs.setString(_keyLastLinkedUserId, state.userId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyDisplayName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyAvatarUrl);
  }

  static Future<String?> loadLastLinkedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastLinkedUserId);
  }
}
