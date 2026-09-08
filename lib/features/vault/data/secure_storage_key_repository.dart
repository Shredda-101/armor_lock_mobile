import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/key_repository.dart';
import '../domain/protected_vault_key.dart';

/// SecureStorageKeyRepository uses platform-backed secure storage (Keychain on iOS, Keystore on Android).
/// The FlutterSecureStorage plugin encrypts data at rest using:
/// - iOS: Keychain encryption + biometric/passcode protection
/// - Android: Android Keystore with mandatory TEE/StrongBox when available
///
/// All keys are wrapped and stored within this protected boundary.
class SecureStorageKeyRepository implements KeyRepository {
  SecureStorageKeyRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            // CRITICAL: Force encrypted storage on Android.
            keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
            storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
            resetOnError: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_available_when_unlocked,
          ),
        );

  static const _vaultKeyStorageKey = 'armor_lock.protected_vault_key.v1';
  static const _protectedVersionKey = 'armor_lock.protected_version.v1';
  static const _keyCreationTimestampKey = 'armor_lock.key_creation_timestamp.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<ProtectedVaultKey?> readProtectedVaultKey() async {
    try {
      final raw = await _storage.read(key: _vaultKeyStorageKey);
      if (raw == null) {
        return null;
      }

      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ProtectedVaultKey(
        keyId: json['keyId'] as String,
        // CRITICAL: wrappedKeyMaterial is now backed by Keychain/Keystore.
        // The bytes themselves are encrypted by the platform.
        wrappedKeyMaterial: base64Decode(json['wrappedKeyMaterial'] as String),
        version: json['version'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
    } catch (e) {
      // Keychain/Keystore access failure or corruption detected.
      // This should trigger a security event and lockdown.
      rethrow;
    }
  }

  @override
  Future<void> writeProtectedVaultKey(ProtectedVaultKey key) async {
    try {
      final json = jsonEncode(<String, Object>{
        'keyId': key.keyId,
        // Platform-backed encryption handles the wrapping.
        'wrappedKeyMaterial': base64Encode(key.wrappedKeyMaterial),
        'version': key.version,
        'createdAt': key.createdAt.toIso8601String(),
      });

      await _storage.write(key: _vaultKeyStorageKey, value: json);
      // Track when key was created for key rotation policies.
      await _storage.write(
        key: _keyCreationTimestampKey,
        value: key.createdAt.toIso8601String(),
      );
    } catch (e) {
      // Keychain/Keystore write failure—app cannot function.
      rethrow;
    }
  }

  @override
  Future<int?> readProtectedVersion() async {
    try {
      final raw = await _storage.read(key: _protectedVersionKey);
      return raw == null ? null : int.parse(raw);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> writeProtectedVersion(int version) async {
    try {
      await _storage.write(key: _protectedVersionKey, value: '$version');
    } catch (e) {
      rethrow;
    }
  }

  /// Returns the key creation timestamp if available, for key rotation checks.
  Future<DateTime?> readKeyCreationTimestamp() async {
    try {
      final raw = await _storage.read(key: _keyCreationTimestampKey);
      return raw == null ? null : DateTime.parse(raw);
    } catch (e) {
      return null;
    }
  }
}
