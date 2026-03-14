import 'package:flutter/foundation.dart';
import 'package:mobile/features/auth/data/repositories/auth.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/profile/data/services/cloud_sync.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ValueNotifier<AuthState?> currentUser = ValueNotifier<AuthState?>(null);

  bool get isLoggedIn => currentUser.value != null;

  bool _loaded = false;

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
    //   await _persistUser(
    //     userId: googleUser.id,
    //     displayName: googleUser.displayName ?? '',
    //     email: googleUser.email,
    //     avatarUrl: googleUser.photoUrl,
    //   );
    await Future<void>.delayed(const Duration(seconds: 2));
    await _persistUser(
      userId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      displayName: '使用者',
      email: 'user@example.com',
    );
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
