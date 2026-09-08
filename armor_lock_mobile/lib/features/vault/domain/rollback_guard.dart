import '../../security_journal/domain/security_event.dart';
import '../../security_journal/domain/security_event_journal.dart';

enum RollbackDecision {
  firstRun,
  accepted,
  rollbackDetected,
}

class RollbackGuard {
  RollbackGuard({required SecurityEventJournal journal}) : _journal = journal;

  final SecurityEventJournal _journal;

  Future<RollbackDecision> compare({
    required int? protectedVersion,
    required int? recoveredLocalVersion,
  }) async {
    if (protectedVersion == null || recoveredLocalVersion == null) {
      return RollbackDecision.firstRun;
    }

    if (recoveredLocalVersion < protectedVersion) {
      await _journal.append(
        SecurityEvent(
          type: SecurityEventType.rollbackDetected,
          occurredAt: DateTime.now(),
          message: 'Recovered local vault version is older than protected state.',
          metadata: <String, String>{
            'protectedVersion': '$protectedVersion',
            'recoveredLocalVersion': '$recoveredLocalVersion',
          },
        ),
      );
      return RollbackDecision.rollbackDetected;
    }

    return RollbackDecision.accepted;
  }
}
