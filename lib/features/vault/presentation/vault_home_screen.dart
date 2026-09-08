import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/domain/auth_controller.dart';
import '../../security_journal/domain/security_event_journal.dart';
import '../../security_journal/presentation/security_centre_screen.dart';
import '../domain/vault_controller.dart';
import '../domain/vault_record.dart';
import '../domain/vault_state.dart';

class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({
    required this.authController,
    required this.vaultController,
    required this.journal,
    super.key,
  });

  final AuthController authController;
  final VaultController vaultController;
  final SecurityEventJournal journal;

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.vaultController,
      builder: (context, _) {
        final state = widget.vaultController.state;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Vault'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Security Centre',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SecurityCentreScreen(journal: widget.journal),
                    ),
                  );
                },
                icon: const Icon(Icons.shield_outlined),
              ),
              IconButton(
                tooltip: 'Lock Vault',
                onPressed: () {
                  unawaited(_lockAndClose());
                },
                icon: const Icon(Icons.lock_outline),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                _VaultHealthPanel(state: state),
                const SizedBox(height: 24),
                Text(
                  'Seal a Secret',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _secretController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Secret text',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: state.status == VaultStatus.ready ? _sealSecret : null,
                  icon: const Icon(Icons.enhanced_encryption_outlined),
                  label: const Text('Encrypt and Seal'),
                ),
                const SizedBox(height: 28),
                Text(
                  'Encrypted Items',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (widget.vaultController.records.isEmpty)
                  const _EmptyVault()
                else
                  for (final record in widget.vaultController.records)
                    Card(
                      child: ListTile(
                        onTap: () => _unsealRecord(record),
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(record.name),
                        subtitle: Text('Version ${record.version}'),
                        trailing: const Icon(Icons.lock_outline),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _unsealRecord(VaultRecord record) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 1. Re-verify identity before showing plaintext
    await widget.authController.unlock();

    if (!widget.authController.state.hasActiveSession) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Authentication required to unseal record.')),
      );
      return;
    }

    try {
      final plainText = await widget.vaultController.unsealText(record);
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_open, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        record.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plainText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    unawaited(Clipboard.setData(ClipboardData(text: plainText)));
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy to Clipboard'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to unseal: $e')),
      );
    }
  }

  Future<void> _sealSecret() async {
    final name = _nameController.text.trim();
    final secret = _secretController.text;
    if (name.isEmpty || secret.isEmpty) {
      return;
    }

    await widget.vaultController.sealText(name: name, text: secret);
    _nameController.clear();
    _secretController.clear();
  }

  Future<void> _lockAndClose() async {
    await widget.authController.lock();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _VaultHealthPanel extends StatelessWidget {
  const _VaultHealthPanel({required this.state});

  final VaultState state;

  @override
  Widget build(BuildContext context) {
    final isLocked = state.status == VaultStatus.permanentlyLocked;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(isLocked ? Icons.report_gmailerrorred : Icons.verified_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isLocked ? 'Vault permanently locked' : 'Vault ready',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(state.message ?? 'Protected version ${state.version}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.inventory_2_outlined),
          SizedBox(width: 12),
          Expanded(child: Text('No encrypted items yet.')),
        ],
      ),
    );
  }
}
