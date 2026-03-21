typedef AuthSessionInvalidatedCallback = void Function();

typedef AuthTokensRefreshedCallback =
    void Function(String accessToken, String refreshToken);

class AuthSessionEvents {
  AuthSessionEvents._();

  static AuthSessionInvalidatedCallback? onSessionInvalidated;
  static AuthTokensRefreshedCallback? onTokensRefreshed;
}
