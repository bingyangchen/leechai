import 'package:mobile/core/auth/credential_store.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyUserId = 'auth_user_id';
const String _keyDisplayName = 'auth_display_name';
const String _keyEmail = 'auth_email';
const String _keyAvatarUrl = 'auth_avatar_url';
const String _keyAccessToken = 'auth_access_token';
const String _keyRefreshToken = 'auth_refresh_token';
const String _keyLastLinkedUserId = 'auth_last_linked_user_id';

class AuthRepository {
  AuthRepository._();

  static Future<AuthState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    final accessToken = prefs.getString(_keyAccessToken);
    final refreshToken = prefs.getString(_keyRefreshToken);
    if (userId == null ||
        userId.isEmpty ||
        accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }
    return AuthState(
      userId: userId,
      displayName: prefs.getString(_keyDisplayName) ?? '',
      email: prefs.getString(_keyEmail) ?? '',
      avatarUrl: prefs.getString(_keyAvatarUrl),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  static Future<void> save(AuthState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, state.userId);
    await prefs.setString(_keyDisplayName, state.displayName);
    await prefs.setString(_keyEmail, state.email);
    await prefs.setString(_keyAccessToken, state.accessToken);
    await prefs.setString(_keyRefreshToken, state.refreshToken);
    if (state.avatarUrl != null) {
      await prefs.setString(_keyAvatarUrl, state.avatarUrl!);
    } else {
      await prefs.remove(_keyAvatarUrl);
    }
    await prefs.setString(_keyLastLinkedUserId, state.userId);
  }

  static Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyDisplayName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyAvatarUrl);
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    // NOTE: Do not remove _keyLastLinkedUserId, which is used to avoid account conflict.
  }

  static Future<String?> loadLastLinkedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastLinkedUserId);
  }
}

class AuthRepositoryCredentials implements AuthCredentialStore {
  const AuthRepositoryCredentials();

  @override
  Future<AuthCredentials?> load() async {
    final state = await AuthRepository.load();
    if (state == null) return null;
    return AuthCredentials(
      accessToken: state.accessToken,
      refreshToken: state.refreshToken,
    );
  }

  @override
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    return AuthRepository.updateTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> clear() => AuthRepository.clear();
}
