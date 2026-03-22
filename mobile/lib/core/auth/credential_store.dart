abstract class AuthCredentialStore {
  Future<AuthCredentials?> load();

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clear();
}

class AuthCredentials {
  const AuthCredentials({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}
