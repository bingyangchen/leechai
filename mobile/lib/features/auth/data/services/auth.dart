import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/features/auth/data/repositories/auth.dart';
import 'package:mobile/features/auth/domain/account_conflict.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/sign_in_cancelled.dart';
import 'package:mobile/features/profile/data/services/cloud_sync.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ValueNotifier<AuthState?> currentUser = ValueNotifier<AuthState?>(null);

  bool get isLoggedIn => currentUser.value != null;

  bool _loaded = false;

  _PendingSignIn? _pendingSignIn;

  static const String _webClientId =
      '1039175482663-b22bnh80h3jd78dae683bm93f1qit2fe.apps.googleusercontent.com';

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
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

    final auth = account.authentication;
    final idToken = auth.idToken;

    if (idToken == null) throw Exception('無法取得 Google ID Token');

    // TODO: 將 idToken 傳送給後端進行驗證，並換取 App 專屬的 Session / JWT
    // final backendResponse = await api.loginWithGoogle(idToken);
    // final appToken = backendResponse.token;

    final userId = account.id;
    final displayName = account.displayName ?? '';
    final email = account.email;
    final avatarUrl = account.photoUrl;

    final lastLinkedId = await AuthRepository.loadLastLinkedUserId();
    if (lastLinkedId != null && lastLinkedId != userId) {
      _pendingSignIn = _PendingSignIn(
        userId: userId,
        displayName: displayName,
        email: email,
        avatarUrl: avatarUrl,
      );
      throw AccountConflictException(
        previousUserId: lastLinkedId,
        newUserId: userId,
        newEmail: email,
      );
    }

    await _persistUser(
      userId: userId,
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
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
    );
  }

  void cancelPendingSignIn() {
    _pendingSignIn = null;
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await AuthRepository.clear();
    currentUser.value = null;
  }

  Future<void> _persistUser({
    required String userId,
    required String displayName,
    required String email,
    String? avatarUrl,
  }) async {
    final state = AuthState(
      userId: userId,
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
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
  });

  final String userId;
  final String displayName;
  final String email;
  final String? avatarUrl;
}
