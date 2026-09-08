# Armor Lock Mobile

Armor Lock Mobile is a high-security, encrypted vault for Android and iOS designed to protect sensitive credentials, notes, and secrets. It focuses on the "Local-First" security model, ensuring that your data stays on your device, protected by the same hardware-backed security that guards your phone.

## 📱 What the App Does

Armor Lock serves as a digital safe for your most sensitive information. 
*   **Encrypted Storage**: Stores your secrets in a local database encrypted with AES-256-GCM.
*   **Hardware Gatekeeping**: The encryption keys are managed by the Android Keystore or iOS Keychain; they are only accessible after a successful biometric or device-passcode challenge.
*   **Tamper Monitoring**: Logs all security-sensitive actions (like failed logins or vault openings) into an audit journal so you can detect if someone has been trying to access your data.
*   **Automatic Protection**: The vault "seals" itself immediately when you switch apps or leave your phone idle, preventing unauthorized access if you leave your device unlocked.

---

## 🔒 Core Security Features

*   **Biometric Protection**: Seamlessly integrates with Android Biometrics (Fingerprint/Face) and iOS FaceID/TouchID.
*   **Hardware-Backed Encryption**: High-performance encryption with keys protected by the device's secure enclave.
*   **Intelligent Lockdown Policy**: 
    *   Monitors consecutive authentication failures.
    *   Automatically triggers a 5-minute cooldown after 5 failed attempts.
    *   Instantly detects and reacts to system-level biometric lockouts.
*   **Security Journal**: A persistent audit trail of every success, failure, and state change.

---

## 🗺️ Future Roadmap (Upcoming Versions)

In the next few releases, we plan to evolve Armor Lock from a local MVP into a production-ready suite:

### v0.4.0: Usability & Organization
*   **Search & Tags**: Quickly find secrets using a lightning-fast local search and custom categorization.
*   **Auto-lock Customization**: Allow users to set their own session timeout (e.g., 30 seconds, 1 minute, 5 minutes).

### v0.5.0: Backup & Recovery
*   **Encrypted Backups**: Export your vault into a password-protected file for manual backups.
*   **Recovery Key**: Generate a 24-word recovery phrase that can restore the vault if biometric data is wiped.

### v0.6.0: Enhanced Media Support
*   **Photo & Document Vault**: Securely store encrypted images (IDs, credit card photos) and PDFs inside the app's protected storage.
*   **In-App Camera**: Capture sensitive documents directly into the encrypted vault without them ever touching the system gallery.

### v1.0.0: Cloud Sync & Advanced Hardware
*   **Zero-Knowledge Sync**: Optional end-to-end encrypted synchronization across devices using private cloud storage (Google Drive/iCloud).
*   **Hardware Security Key Support**: Support for physical keys (like YubiKeys) as an additional factor for ultra-high-security profiles.

---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (>= 3.4.0)
*   Android Studio / Xcode
*   A physical device (recommended for biometric testing)

### Installation
1.  Run dependencies: `flutter pub get`
2.  Ensure `android/local.properties` contains your `sdk.dir`.
3.  Run the app: `flutter run`

---

*Note: This is an MVP implementation focused on providing a robust security foundation. Authoritative keys and protected counters are managed via native platform adapters.*
