import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AppVersionTracker maintains an independent, external version counter in secure storage.
/// This counter is incremented each time the app state mutates (vault operations).
/// The protected vault version is compared against this external version to detect rollback:
/// - If external version > protected version: Rollback detected (restore from backup attempted)
/// - If external version == protected version: Normal operation
/// - If external version < protected version: Clock skew or system tampering (suspicious)
///
/// This prevents attackers from:
/// 1. Restoring the app to an earlier state
/// 2. Bypassing vault mutations
/// 3. Replay-attacking earlier vault contents
class AppVersionTracker {
  AppVersionTracker({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
            storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_available_when_unlocked,
          ),
        );

  static const _externalVersionKey = 'armor_lock.external_app_version.v1';

  final FlutterSecureStorage _storage;

  /// Reads the current external version from secure storage.
  /// Returns 0 if not yet initialized (first run).
  Future<int> readExternalVersion() async {
    try {
      final raw = await _storage.read(key: _externalVersionKey);
      return raw == null ? 0 : int.parse(raw);
    } catch (e) {
      // Default to 0 on error to trigger rollback detection.
      return 0;
    }
  }

  /// Increments and persists the external version counter.
  /// Called after every vault mutation to advance the external state.
  Future<int> incrementExternalVersion() async {
    try {
      final current = await readExternalVersion();
      final next = current + 1;
      await _storage.write(key: _externalVersionKey, value: '$next');
      return next;
    } catch (e) {
      rethrow;
    }
  }

  /// Explicitly sets the external version (use with caution—primarily for testing).
  Future<void> setExternalVersion(int version) async {
    try {
      await _storage.write(key: _externalVersionKey, value: '$version');
    } catch (e) {
      rethrow;
    }
  }
}
