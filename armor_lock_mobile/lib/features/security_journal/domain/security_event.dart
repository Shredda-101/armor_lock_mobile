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

  /// Serializes the event to JSON for disk persistence.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'occurredAt': occurredAt.toIso8601String(),
      'message': message,
      'metadata': metadata,
    };
  }

  /// Deserializes from JSON (used when reading persisted events).
  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      type: SecurityEventType.values.byName(json['type'] as String),
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      message: json['message'] as String,
      metadata: Map<String, String>.from(json['metadata'] as Map<String, dynamic>? ?? <String, String>{}),
    );
  }
}
