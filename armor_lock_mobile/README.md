# Armor Lock Mobile

Armor Lock Mobile is a Flutter MVP for a private encrypted vault guarded by operating-system authentication and platform-backed key protection.

This scaffold starts version `0.3.0` with:

- Lock/session state machine
- Five-attempt lockdown policy
- Tamper-evident event journal model
- AES-256-GCM vault crypto service boundary
- Rollback detection contract
- Secure storage adapter boundary for Keychain/Keystore-backed values
- Initial lock screen, vault screen, and security centre UI

## Local setup

Flutter is not installed in this Codex workspace. After installing Flutter, run:

```powershell
flutter pub get
flutter test
flutter run
```

## Security note

The MVP deliberately keeps local app state untrusted. Plain local state can drive UI hints, but it must not become the root of trust. Authoritative keys and protected counters belong behind native Keychain/Keystore adapters.
