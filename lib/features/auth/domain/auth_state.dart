enum AuthStatus {
  locked,
  authenticating,
  unlocked,
  lockdown,
}

class AuthState {
  const AuthState({
    required this.status,
    required this.consecutiveFailures,
    this.sessionExpiresAt,
    this.lockdownUntil,
    this.message,
  });

  const AuthState.locked()
      : status = AuthStatus.locked,
        consecutiveFailures = 0,
        sessionExpiresAt = null,
        lockdownUntil = null,
        message = null;

  final AuthStatus status;
  final int consecutiveFailures;
  final DateTime? sessionExpiresAt;
  final DateTime? lockdownUntil;
  final String? message;

  bool get hasActiveSession {
    final expiresAt = sessionExpiresAt;
    return status == AuthStatus.unlocked &&
        expiresAt != null &&
        DateTime.now().isBefore(expiresAt);
  }

  AuthState copyWith({
    AuthStatus? status,
    int? consecutiveFailures,
    DateTime? sessionExpiresAt,
    DateTime? lockdownUntil,
    String? message,
    bool clearSession = false,
    bool clearLockdown = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      sessionExpiresAt:
          clearSession ? null : sessionExpiresAt ?? this.sessionExpiresAt,
      lockdownUntil:
          clearLockdown ? null : lockdownUntil ?? this.lockdownUntil,
      message: message,
    );
  }
}
