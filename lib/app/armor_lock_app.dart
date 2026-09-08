import 'package:flutter/material.dart';

import '../features/auth/data/local_authenticator.dart';
import '../features/auth/domain/auth_controller.dart';
import '../features/auth/domain/lock_policy.dart';
import '../features/auth/presentation/lock_gate_screen.dart';
import '../features/security_journal/data/persistent_security_event_journal.dart';
import '../features/security_journal/domain/security_event_journal.dart';
import '../features/vault/crypto/vault_crypto_service.dart';
import '../features/vault/data/app_version_tracker.dart';
import '../features/vault/data/local_file_vault_record_repository.dart';
import '../features/vault/data/secure_storage_key_repository.dart';
import '../features/vault/domain/rollback_guard.dart';
import '../features/vault/domain/vault_controller.dart';

class ArmorLockApp extends StatefulWidget {
  const ArmorLockApp({super.key});

  @override
  State<ArmorLockApp> createState() => _ArmorLockAppState();
}

class _ArmorLockAppState extends State<ArmorLockApp> with WidgetsBindingObserver {
  late final SecurityEventJournal _journal;
  late final AuthController _authController;
  late final VaultController _vaultController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // CRITICAL: Use persistent journal for audit trail and forensics.
    // Events survive app restarts and tamper-evident history is maintained.
    _journal = PersistentSecurityEventJournal();

    _authController = AuthController(
      authenticator: LocalDeviceAuthenticator(),
      journal: _journal,
      lockPolicy: const LockPolicy(),
    );

    final versionTracker = AppVersionTracker();

    _vaultController = VaultController(
      cryptoService: VaultCryptoService(),
      keyRepository: SecureStorageKeyRepository(),
      recordRepository: LocalFileVaultRecordRepository(),
      rollbackGuard: RollbackGuard(journal: _journal, versionTracker: versionTracker),
      journal: _journal,
      versionTracker: versionTracker,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Automatically lock the vault when the app is backgrounded or paused.
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _authController.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Armor Lock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff246b5f),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff101315),
        useMaterial3: true,
      ),
      home: LockGateScreen(
        authController: _authController,
        vaultController: _vaultController,
        journal: _journal,
      ),
    );
  }
}
