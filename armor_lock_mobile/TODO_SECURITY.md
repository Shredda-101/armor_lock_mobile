# Security Hardening Backlog

Before production release:

- Replace `InMemorySecurityEventJournal` with a persisted append-only journal.
- Replace the MVP `wrappedKeyMaterial` placeholder with native Keychain/Keystore key wrapping.
- Add platform-specific Android StrongBox capability checks and fallback policy.
- Add iOS Keychain access-control flags requiring current biometric set or device passcode.
- Persist encrypted vault records and metadata with authenticated version fields.
- Add lifecycle auto-lock on pause, background, and process restart.
- Add corruption, rollback, ciphertext tamper, expired-session, and app-kill tests.
- Commission an independent security review.
