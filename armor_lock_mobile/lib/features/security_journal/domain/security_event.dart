enum SecurityEventType {
  authSuccess,
  authFailure,
  lockdown,
  vaultLock,
  keyError,
  rollbackDetected,
  vaultOpened,
  vaultSealed,
}

class SecurityEvent {
  const SecurityEvent({
    required this.type,
    required this.occurredAt,
    required this.message,
    this.metadata = const <String, String>{},
  });

  final SecurityEventType type;
  final DateTime occurredAt;
  final String message;
  final Map<String, String> metadata;
}
