import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

import '../domain/device_authenticator.dart';

class LocalDeviceAuthenticator implements DeviceAuthenticator {
  LocalDeviceAuthenticator({LocalAuthentication? localAuthentication})
      : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<AuthResult> authenticate() async {
    try {
      final canAuthenticate = await _localAuthentication.canCheckBiometrics ||
          await _localAuthentication.isDeviceSupported();

      if (!canAuthenticate) {
        return AuthResult.failure;
      }

      final success = await _localAuthentication.authenticate(
        localizedReason: 'Unlock your Armor Lock vault',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      return success ? AuthResult.success : AuthResult.failure;
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.biometricLockout ||
          e.code == LocalAuthExceptionCode.temporaryLockout) {
        return AuthResult.lockout;
      }
      return AuthResult.error;
    } catch (_) {
      return AuthResult.error;
    }
  }
}
