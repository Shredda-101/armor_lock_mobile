import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/key_repository.dart';
import '../domain/protected_vault_key.dart';

class SecureStorageKeyRepository implements KeyRepository {
  SecureStorageKeyRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _vaultKeyStorageKey = 'armor_lock.protected_vault_key';
  static const _protectedVersionKey = 'armor_lock.protected_version';

  final FlutterSecureStorage _storage;

  @override
  Future<ProtectedVaultKey?> readProtectedVaultKey() async {
    final raw = await _storage.read(key: _vaultKeyStorageKey);
    if (raw == null) {
      return null;
    }

    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ProtectedVaultKey(
      keyId: json['keyId'] as String,
      wrappedKeyMaterial: base64Decode(json['wrappedKeyMaterial'] as String),
      version: json['version'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  Future<void> writeProtectedVaultKey(ProtectedVaultKey key) {
    return _storage.write(
      key: _vaultKeyStorageKey,
      value: jsonEncode(<String, Object>{
        'keyId': key.keyId,
        'wrappedKeyMaterial': base64Encode(key.wrappedKeyMaterial),
        'version': key.version,
        'createdAt': key.createdAt.toIso8601String(),
      }),
    );
  }

  @override
  Future<int?> readProtectedVersion() async {
    final raw = await _storage.read(key: _protectedVersionKey);
    return raw == null ? null : int.parse(raw);
  }

  @override
  Future<void> writeProtectedVersion(int version) {
    return _storage.write(key: _protectedVersionKey, value: '$version');
  }
}
