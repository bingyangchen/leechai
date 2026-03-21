class AuthTokenError(Exception):
    pass


class InvalidRefreshTokenError(AuthTokenError):
    pass


class RefreshTokenReuseDetectedError(AuthTokenError):
    pass


class RefreshTokenExpiredError(AuthTokenError):
    pass


class RefreshTokenUserNotFoundError(AuthTokenError):
    pass
