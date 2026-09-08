import 'package:armor_lock_mobile/features/security_journal/domain/security_event.dart';
import 'package:armor_lock_mobile/features/security_journal/domain/security_event_journal.dart';
import 'package:armor_lock_mobile/features/vault/domain/rollback_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts matching protected and recovered versions', () async {
    final guard = RollbackGuard(journal: InMemorySecurityEventJournal());

    final decision = await guard.compare(
      protectedVersion: 44,
      recoveredLocalVersion: 44,
    );

    expect(decision, RollbackDecision.accepted);
  });

  test('detects recovered local version older than protected version', () async {
    final journal = InMemorySecurityEventJournal();
    final guard = RollbackGuard(journal: journal);

    final decision = await guard.compare(
      protectedVersion: 44,
      recoveredLocalVersion: 41,
    );

    expect(decision, RollbackDecision.rollbackDetected);
    final events = await journal.latest();
    expect(events.single.type, SecurityEventType.rollbackDetected);
  });
}
