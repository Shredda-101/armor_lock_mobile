import 'protected_vault_key.dart';

abstract interface class KeyRepository {
  Future<ProtectedVaultKey?> readProtectedVaultKey();
  Future<void> writeProtectedVaultKey(ProtectedVaultKey key);
  Future<int?> readProtectedVersion();
  Future<void> writeProtectedVersion(int version);
}
