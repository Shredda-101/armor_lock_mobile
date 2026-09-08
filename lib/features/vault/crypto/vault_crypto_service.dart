import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

import '../domain/protected_vault_key.dart';
import '../domain/vault_record.dart';

class VaultCryptoService {
  VaultCryptoService({
    AesGcm? aesGcm,
    Uuid? uuid,
  })  : _aesGcm = aesGcm ?? AesGcm.with256bits(),
        _uuid = uuid ?? const Uuid();

  final AesGcm _aesGcm;
  final Uuid _uuid;

  Future<ProtectedVaultKey> createVaultKey({int version = 1}) async {
    final secretKey = await _aesGcm.newSecretKey();
    final keyBytes = await secretKey.extractBytes();

    return ProtectedVaultKey(
      keyId: _uuid.v4(),
      // TODO: Replace with native Keychain/Keystore wrapping adapter.
      wrappedKeyMaterial: keyBytes,
      version: version,
      createdAt: DateTime.now(),
    );
  }

  Future<VaultRecord> encryptText({
    required ProtectedVaultKey protectedKey,
    required String name,
    required String plainText,
    required int version,
  }) async {
    final secretKey = SecretKey(protectedKey.wrappedKeyMaterial);
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
    );

    return VaultRecord(
      id: _uuid.v4(),
      name: name,
      cipherText: secretBox.cipherText,
      nonce: secretBox.nonce,
      mac: secretBox.mac.bytes,
      version: version,
      updatedAt: DateTime.now(),
    );
  }

  Future<String> decryptText({
    required ProtectedVaultKey protectedKey,
    required VaultRecord record,
  }) async {
    final secretKey = SecretKey(protectedKey.wrappedKeyMaterial);
    final clearBytes = await _aesGcm.decrypt(
      SecretBox(
        record.cipherText,
        nonce: record.nonce,
        mac: Mac(record.mac),
      ),
      secretKey: secretKey,
    );

    return utf8.decode(clearBytes);
  }
}
