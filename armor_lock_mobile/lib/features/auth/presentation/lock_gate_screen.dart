import 'dart:async';

import 'package:flutter/material.dart';

import '../../security_journal/domain/security_event_journal.dart';
import '../../security_journal/presentation/security_centre_screen.dart';
import '../../vault/domain/vault_controller.dart';
import '../../vault/presentation/vault_home_screen.dart';
import '../domain/auth_controller.dart';
import '../domain/auth_state.dart';

class LockGateScreen extends StatefulWidget {
  const LockGateScreen({
    required this.authController,
    required this.vaultController,
    required this.journal,
    super.key,
  });

  final AuthController authController;
  final VaultController vaultController;
  final SecurityEventJournal journal;

  @override
  State<LockGateScreen> createState() => _LockGateScreenState();
}

class _LockGateScreenState extends State<LockGateScreen> {
  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    unawaited(_openVaultWhenUnlocked());
  }

  Future<void> _openVaultWhenUnlocked() async {
    if (!mounted || !widget.authController.state.hasActiveSession) {
      return;
    }
    await widget.vaultController.initialize();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VaultHomeScreen(
          authController: widget.authController,
          vaultController: widget.vaultController,
          journal: widget.journal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.authController,
      builder: (context, _) {
        final state = widget.authController.state;
        final isAuthenticating = state.status == AuthStatus.authenticating;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Security Centre',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SecurityCentreScreen(
                              journal: widget.journal,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shield_outlined),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.lock_outline,
                    size: 76,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Armor Lock',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _messageFor(state),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: isAuthenticating
                        ? null
                        : () {
                            unawaited(widget.authController.unlock());
                          },
                    icon: isAuthenticating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: Text(isAuthenticating ? 'Authenticating' : 'Unlock Vault'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SecurityCentreScreen(
                            journal: widget.journal,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('View Security Events'),
                  ),
                  const Spacer(),
                  _LockStatusStrip(state: state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _messageFor(AuthState state) {
    if (state.status == AuthStatus.lockdown) {
      final until = state.lockdownUntil;
      return until == null
          ? 'Temporary lockdown is active.'
          : 'Temporary lockdown until ${TimeOfDay.fromDateTime(until).format(context)}.';
    }
    return state.message ??
        'Protected by device authentication and hardware-backed key storage.';
  }
}

class _LockStatusStrip extends StatelessWidget {
  const _LockStatusStrip({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            state.status == AuthStatus.lockdown
                ? Icons.gpp_bad_outlined
                : Icons.verified_user_outlined,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed attempts: ${state.consecutiveFailures}/5',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
