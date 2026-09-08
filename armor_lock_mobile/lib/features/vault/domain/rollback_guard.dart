import '../../security_journal/domain/security_event.dart';
import '../../security_journal/domain/security_event_journal.dart';
import '../data/app_version_tracker.dart';

enum RollbackDecision {
  firstRun,
  accepted,
  rollbackDetected,
}

/// RollbackGuard detects attempts to restore the app to an earlier state (rollback attacks).
///
/// Attack scenario: Attacker backs up the app at vault version 5, modifies data,
/// then restores from backup to vault version 5. The vault would replay old operations.
///
/// Detection: Compare the protected vault version against an external version counter
/// that's incremented on every vault mutation and stored in secure storage:
/// - external_version >= protected_version: Normal operation
/// - external_version < protected_version: Rollback detected—vault was restored to earlier state
class RollbackGuard {
  RollbackGuard({
    required SecurityEventJournal journal,
    required AppVersionTracker versionTracker,
  })  : _journal = journal,
        _versionTracker = versionTracker;

  final SecurityEventJournal _journal;
  final AppVersionTracker _versionTracker;

  /// Compares the protected vault version against the external app version.
  /// If external version has gone backwards, rollback is detected.
  Future<RollbackDecision> compare({
    required int? protectedVersion,
  }) async {
    if (protectedVersion == null) {
      return RollbackDecision.firstRun;
    }

    final externalVersion = await _versionTracker.readExternalVersion();

    // CRITICAL: If external version < protected version, the app state was rolled back.
    if (externalVersion < protectedVersion) {
      await _journal.append(
        SecurityEvent(
          type: SecurityEventType.rollbackDetected,
          occurredAt: DateTime.now(),
          message: 'Rollback detected: external version regressed.',
          metadata: <String, String>{
            'protectedVersion': '$protectedVersion',
            'externalVersion': '$externalVersion',
          },
        ),
      );
      return RollbackDecision.rollbackDetected;
    }

    // Sync external version to match protected version if ahead
    // (e.g., after key rotation or manual version bump).
    if (externalVersion > protectedVersion) {
      await _versionTracker.setExternalVersion(protectedVersion);
    }

    return RollbackDecision.accepted;
  }
}
