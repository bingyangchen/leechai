import 'package:flutter/foundation.dart';
import 'package:mobile/features/auth/data/repositories/auth.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';

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

  Future<void> signIn({
    required String userId,
    required String displayName,
    required String email,
  }) async {
    final state = AuthState(userId: userId, displayName: displayName, email: email);
    await AuthRepository.save(state);
    currentUser.value = state;
  }

  Future<void> signOut() async {
    await AuthRepository.clear();
    currentUser.value = null;
  }
}
