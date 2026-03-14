import 'package:flutter/foundation.dart';
import 'package:mobile/features/auth/data/repositories/auth.dart';
import 'package:mobile/features/auth/domain/account_conflict.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/profile/data/services/cloud_sync.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ValueNotifier<AuthState?> currentUser = ValueNotifier<AuthState?>(null);

  bool get isLoggedIn => currentUser.value != null;

  bool _loaded = false;

  _PendingSignIn? _pendingSignIn;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final state = await AuthRepository.load();
    currentUser.value = state;
    _loaded = true;
  }

  Future<void> signInWithGoogle() async {
    // TODO: Replace mock with actual GoogleSignIn SDK call:
    //   final googleUser = await GoogleSignIn().signIn();
    //   if (googleUser == null) throw const SignInCancelledException();
    //   final userId = googleUser.id;
    //   final displayName = googleUser.displayName ?? '';
    //   final email = googleUser.email;
    //   final avatarUrl = googleUser.photoUrl;
    await Future<void>.delayed(const Duration(seconds: 2));
    final userId = 'mock-${DateTime.now().millisecondsSinceEpoch}';
    const displayName = '使用者';
    const email = 'user@example.com';
    const String? avatarUrl = null;

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
    CloudSyncService.instance.syncIfNeeded().catchError((_, __) {});
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
