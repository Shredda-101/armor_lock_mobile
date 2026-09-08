import 'package:flutter/foundation.dart';

import '../../security_journal/domain/security_event.dart';
import '../../security_journal/domain/security_event_journal.dart';
import '../crypto/vault_crypto_service.dart';
import 'key_repository.dart';
import 'protected_vault_key.dart';
import 'rollback_guard.dart';
import 'vault_record.dart';
import 'vault_record_repository.dart';
import 'vault_state.dart';

class VaultController extends ChangeNotifier {
  VaultController({
    required VaultCryptoService cryptoService,
    required KeyRepository keyRepository,
    required VaultRecordRepository recordRepository,
    required RollbackGuard rollbackGuard,
    required SecurityEventJournal journal,
  })  : _cryptoService = cryptoService,
        _keyRepository = keyRepository,
        _recordRepository = recordRepository,
        _rollbackGuard = rollbackGuard,
        _journal = journal;

  final VaultCryptoService _cryptoService;
  final KeyRepository _keyRepository;
  final VaultRecordRepository _recordRepository;
  final RollbackGuard _rollbackGuard;
  final SecurityEventJournal _journal;

  VaultState _state = const VaultState.unknown();
  final List<VaultRecord> _records = <VaultRecord>[];
  ProtectedVaultKey? _protectedKey;

  VaultState get state => _state;
  List<VaultRecord> get records => List<VaultRecord>.unmodifiable(_records);

  Future<void> initialize({int? recoveredLocalVersion}) async {
    final storedKey = await _keyRepository.readProtectedVaultKey();
    final protectedVersion = await _keyRepository.readProtectedVersion();

    final rollbackDecision = await _rollbackGuard.compare(
      protectedVersion: protectedVersion,
      recoveredLocalVersion: recoveredLocalVersion ?? protectedVersion,
    );

    if (rollbackDecision == RollbackDecision.rollbackDetected) {
      _state = const VaultState(
        status: VaultStatus.permanentlyLocked,
        version: 0,
        message: 'Rollback detected. Vault access is denied.',
      );
      notifyListeners();
      return;
    }

    _records.clear();
    _records.addAll(await _recordRepository.loadRecords());

    if (storedKey == null) {
      final newKey = await _cryptoService.createVaultKey();
      await _keyRepository.writeProtectedVaultKey(newKey);
      await _keyRepository.writeProtectedVersion(newKey.version);
      _protectedKey = newKey;
      _state = VaultState(status: VaultStatus.ready, version: newKey.version);
      notifyListeners();
      return;
    }

    _protectedKey = storedKey;
    _state = VaultState(status: VaultStatus.ready, version: storedKey.version);
    notifyListeners();
  }

  Future<void> sealText({required String name, required String text}) async {
    final key = _protectedKey;
    if (key == null) {
      await _journal.append(
        SecurityEvent(
          type: SecurityEventType.keyError,
          occurredAt: DateTime.now(),
          message: 'Vault key unavailable during seal operation.',
        ),
      );
      _state = const VaultState(
        status: VaultStatus.keyUnavailable,
        version: 0,
        message: 'Protected vault key is unavailable.',
      );
      notifyListeners();
      return;
    }

    final nextVersion = key.version + 1;
    final record = await _cryptoService.encryptText(
      protectedKey: key,
      name: name,
      plainText: text,
      version: nextVersion,
    );

    final nextKey = ProtectedVaultKey(
      keyId: key.keyId,
      wrappedKeyMaterial: key.wrappedKeyMaterial,
      version: nextVersion,
      createdAt: key.createdAt,
    );

    _records.insert(0, record);
    _protectedKey = nextKey;
    await _recordRepository.saveRecords(_records);
    await _keyRepository.writeProtectedVaultKey(nextKey);
    await _keyRepository.writeProtectedVersion(nextVersion);
    await _journal.append(
      SecurityEvent(
        type: SecurityEventType.vaultSealed,
        occurredAt: DateTime.now(),
        message: 'Encrypted vault item sealed.',
        metadata: <String, String>{'recordId': record.id, 'version': '$nextVersion'},
      ),
    );

    _state = VaultState(status: VaultStatus.ready, version: nextVersion);
    notifyListeners();
  }

  Future<String> unsealText(VaultRecord record) async {
    final key = _protectedKey;
    if (key == null) {
      throw Exception('Vault key is unavailable.');
    }

    final plainText = await _cryptoService.decryptText(
      protectedKey: key,
      record: record,
    );

    await _journal.append(
      SecurityEvent(
        type: SecurityEventType.vaultOpened,
        occurredAt: DateTime.now(),
        message: 'Encrypted vault item unsealed.',
        metadata: <String, String>{'recordId': record.id},
      ),
    );

    return plainText;
  }
}
