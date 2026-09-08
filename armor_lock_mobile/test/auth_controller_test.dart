import 'package:armor_lock_mobile/features/auth/domain/auth_controller.dart';
import 'package:armor_lock_mobile/features/auth/domain/auth_state.dart';
import 'package:armor_lock_mobile/features/auth/domain/device_authenticator.dart';
import 'package:armor_lock_mobile/features/auth/domain/lock_policy.dart';
import 'package:armor_lock_mobile/features/security_journal/domain/security_event.dart';
import 'package:armor_lock_mobile/features/security_journal/domain/security_event_journal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('successful authentication starts a short-lived session', () async {
    final controller = AuthController(
      authenticator: _FakeAuthenticator(results: <bool>[true]),
      journal: InMemorySecurityEventJournal(),
      lockPolicy: const LockPolicy(),
    );

    await controller.unlock();

    expect(controller.state.status, AuthStatus.unlocked);
    expect(controller.state.consecutiveFailures, 0);
    expect(controller.state.sessionExpiresAt, isNotNull);
  });

  test('five consecutive failures trigger lockdown', () async {
    final journal = InMemorySecurityEventJournal();
    final controller = AuthController(
      authenticator: _FakeAuthenticator(
        results: List<bool>.filled(5, false),
      ),
      journal: journal,
      lockPolicy: const LockPolicy(
        failureThreshold: 5,
        lockdownDuration: Duration(minutes: 5),
      ),
    );

    for (var i = 0; i < 5; i++) {
      await controller.unlock();
    }

    expect(controller.state.status, AuthStatus.lockdown);
    expect(controller.state.consecutiveFailures, 5);
    expect(controller.state.lockdownUntil, isNotNull);

    final events = await journal.latest();
    expect(events.first.type, SecurityEventType.lockdown);
  });
}

class _FakeAuthenticator implements DeviceAuthenticator {
  _FakeAuthenticator({required List<bool> results}) : _results = results;

  final List<bool> _results;
  var _index = 0;

  @override
  Future<bool> authenticate() async {
    return _results[_index++];
  }
}
