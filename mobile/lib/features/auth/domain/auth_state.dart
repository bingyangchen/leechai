class AuthState {
  const AuthState({
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
