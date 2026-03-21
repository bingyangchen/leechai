class AuthState {
  const AuthState({
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
