import 'package:flutter/foundation.dart';

import '../../security_journal/domain/security_event.dart';
import '../../security_journal/domain/security_event_journal.dart';
import 'auth_state.dart';
import 'device_authenticator.dart';
import 'lock_policy.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required DeviceAuthenticator authenticator,
    required SecurityEventJournal journal,
    required LockPolicy lockPolicy,
  })  : _authenticator = authenticator,
        _journal = journal,
        _lockPolicy = lockPolicy;

  final DeviceAuthenticator _authenticator;
  final SecurityEventJournal _journal;
  final LockPolicy _lockPolicy;

  AuthState _state = const AuthState.locked();

  AuthState get state => _state;

  /// Verifies that the current session is still valid.
  /// If expired, immediately locks the vault.
  /// Returns true if session is active, false if expired/locked.
  bool verifySessionValid() {
    final now = DateTime.now();
    final expiresAt = _state.sessionExpiresAt;

    // Session must exist and not be expired.
    if (expiresAt != null && now.isAfter(expiresAt)) {
      // Session expired—lock immediately.
      _state = const AuthState.locked();
      _journal.append(
        SecurityEvent(
          type: SecurityEventType.vaultLock,
          occurredAt: DateTime.now(),
          message: 'Session expired. Vault auto-locked.',
        ),
      );
      notifyListeners();
      return false;
    }

    return _state.hasActiveSession;
  }

  Future<void> unlock() async {
    final now = DateTime.now();
    final lockedUntil = _state.lockdownUntil;
    if (lockedUntil != null && now.isBefore(lockedUntil)) {
      _state = _state.copyWith(
        status: AuthStatus.lockdown,
        message: 'Temporary lockdown is active.',
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      status: AuthStatus.authenticating,
      clearLockdown: true,
      message: null,
    );
    notifyListeners();

    final result = await _authenticator.authenticate();

    if (result == AuthResult.success) {
      await _journal.append(
        SecurityEvent(
          type: SecurityEventType.authSuccess,
          occurredAt: DateTime.now(),
          message: 'System authentication succeeded.',
        ),
      );
      _state = AuthState(
        status: AuthStatus.unlocked,
        consecutiveFailures: 0,
        sessionExpiresAt: DateTime.now().add(_lockPolicy.sessionDuration),
      );
      notifyListeners();
      return;
    }

    // Handle failure, lockout, or error
    int failures;
    if (result == AuthResult.lockout) {
      // If system reports lockout, we immediately jump to the threshold to lock the app
      failures = _lockPolicy.failureThreshold;
    } else {
      failures = _state.consecutiveFailures + 1;
    }

    await _journal.append(
      SecurityEvent(
        type: SecurityEventType.authFailure,
        occurredAt: DateTime.now(),
        message: result == AuthResult.lockout
            ? 'System lockout detected.'
            : 'System authentication failed.',
        metadata: <String, String>{
          'failures': '$failures',
          'result': result.name,
        },
      ),
    );

    final lockdownUntil = _lockPolicy.lockdownUntil(
      consecutiveFailures: failures,
      now: DateTime.now(),
    );

    if (lockdownUntil != null) {
      await _journal.append(
        SecurityEvent(
          type: SecurityEventType.lockdown,
          occurredAt: DateTime.now(),
          message: 'Lockdown threshold reached.',
          metadata: <String, String>{'until': lockdownUntil.toIso8601String()},
        ),
      );
    }

    _state = AuthState(
      status: lockdownUntil == null ? AuthStatus.locked : AuthStatus.lockdown,
      consecutiveFailures: failures,
      lockdownUntil: lockdownUntil,
      message: result == AuthResult.lockout
          ? 'Too many attempts. System locked.'
          : (lockdownUntil == null
              ? 'Authentication failed.'
              : 'Too many failed attempts.'),
    );
    notifyListeners();
  }

  Future<void> lock() async {
    await _journal.append(
      SecurityEvent(
        type: SecurityEventType.vaultLock,
        occurredAt: DateTime.now(),
        message: 'Session ended and vault locked.',
      ),
    );
    _state = const AuthState.locked();
    notifyListeners();
  }
}
