class LockPolicy {
  const LockPolicy({
    this.failureThreshold = 5,
    this.lockdownDuration = const Duration(minutes: 5),
    this.sessionDuration = const Duration(minutes: 3),
  });

  final int failureThreshold;
  final Duration lockdownDuration;
  final Duration sessionDuration;

  DateTime? lockdownUntil({
    required int consecutiveFailures,
    required DateTime now,
  }) {
    if (consecutiveFailures < failureThreshold) {
      return null;
    }
    return now.add(lockdownDuration);
  }
}
