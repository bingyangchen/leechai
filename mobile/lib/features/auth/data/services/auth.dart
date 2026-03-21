import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/core/auth/auth_session_events.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/auth/data/apis/auth.dart';
import 'package:mobile/features/auth/data/repositories/auth.dart';
import 'package:mobile/features/auth/domain/account_conflict.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/sign_in_cancelled.dart';
import 'package:mobile/features/profile/data/services/cloud_sync.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final AuthApi _authApi = AuthApi(client: ApiClient());

  final ValueNotifier<AuthState?> currentUser = ValueNotifier<AuthState?>(null);

  bool get isLoggedIn => currentUser.value != null;

  bool _loaded = false;

  _PendingSignIn? _pendingSignIn;

  static const String _webClientId =
      '1039175482663-b22bnh80h3jd78dae683bm93f1qit2fe.apps.googleusercontent.com';

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
    AuthSessionEvents.onTokensRefreshed = (accessToken, refreshToken) {
      final user = currentUser.value;
      if (user == null) return;
      currentUser.value = AuthState(
        userId: user.userId,
        displayName: user.displayName,
        email: user.email,
        avatarUrl: user.avatarUrl,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    };
    AuthSessionEvents.onSessionInvalidated = () {
      currentUser.value = null;
    };
    final state = await AuthRepository.load();
    currentUser.value = state;
    _loaded = true;
  }

  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SignInCancelledException();
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) throw Exception('無法取得 Google ID Token');

    final login = await _authApi.loginWithGoogle(idToken);

    final lastLinkedId = await AuthRepository.loadLastLinkedUserId();
    if (lastLinkedId != null && lastLinkedId != login.userId) {
      _pendingSignIn = _PendingSignIn(
        userId: login.userId,
        displayName: login.displayName,
        email: login.email,
        avatarUrl: login.avatarUrl,
        accessToken: login.accessToken,
        refreshToken: login.refreshToken,
      );
      throw AccountConflictException(
        previousUserId: lastLinkedId,
        newUserId: login.userId,
        newEmail: login.email,
      );
    }

    await _persistUser(
      userId: login.userId,
      displayName: login.displayName,
      email: login.email,
      avatarUrl: login.avatarUrl,
      accessToken: login.accessToken,
      refreshToken: login.refreshToken,
    );
  }

  Future<void> confirmSignInWithDifferentAccount() async {
    final pending = _pendingSignIn;
    if (pending == null) return;
    _pendingSignIn = null;
    await _persistUser(
      userId: pending.userId,
      displayName: pending.displayName,
      email: pending.email,
      avatarUrl: pending.avatarUrl,
      accessToken: pending.accessToken,
      refreshToken: pending.refreshToken,
    );
  }

  void cancelPendingSignIn() {
    _pendingSignIn = null;
  }

  Future<void> signOut() async {
    final refresh = currentUser.value?.refreshToken;
    await GoogleSignIn.instance.signOut();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _authApi.logout(refresh);
      } catch (_) {}
    }
    await AuthRepository.clear();
    currentUser.value = null;
  }

  Future<void> _persistUser({
    required String userId,
    required String displayName,
    required String email,
    String? avatarUrl,
    required String accessToken,
    required String refreshToken,
  }) async {
    final state = AuthState(
      userId: userId,
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await AuthRepository.save(state);
    currentUser.value = state;
    CloudSyncService.instance.syncIfNeeded().catchError((_, stackTrace) {});
  }
}

class _PendingSignIn {
  const _PendingSignIn({
    required this.userId,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    required this.accessToken,
    required this.refreshToken,
  });

  final String userId;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String accessToken;
  final String refreshToken;
}
