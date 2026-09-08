enum AuthResult {
  success,
  failure,
  lockout,
  error,
}

abstract interface class DeviceAuthenticator {
  Future<AuthResult> authenticate();
}
