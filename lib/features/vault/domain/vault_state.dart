enum VaultStatus {
  unknown,
  ready,
  sealed,
  permanentlyLocked,
  keyUnavailable,
}

class VaultState {
  const VaultState({
    required this.status,
    required this.version,
    this.message,
  });

  const VaultState.unknown()
      : status = VaultStatus.unknown,
        version = 0,
        message = null;

  final VaultStatus status;
  final int version;
  final String? message;
}
