import 'package:flutter/material.dart';

import '../domain/security_event.dart';
import '../domain/security_event_journal.dart';

class SecurityCentreScreen extends StatelessWidget {
  const SecurityCentreScreen({required this.journal, super.key});

  final SecurityEventJournal journal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Centre')),
      body: FutureBuilder<List<SecurityEvent>>(
        future: journal.latest(),
        builder: (context, snapshot) {
          final events = snapshot.data ?? const <SecurityEvent>[];
          if (events.isEmpty) {
            return const Center(
              child: Text('No security events recorded in this session.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: Icon(_iconFor(event.type)),
                title: Text(_labelFor(event.type)),
                subtitle: Text(event.message),
                trailing: Text(
                  TimeOfDay.fromDateTime(event.occurredAt).format(context),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(SecurityEventType type) {
    return switch (type) {
      SecurityEventType.authSuccess => Icons.check_circle_outline,
      SecurityEventType.authFailure => Icons.error_outline,
      SecurityEventType.lockdown => Icons.timer_outlined,
      SecurityEventType.vaultLock => Icons.lock_outline,
      SecurityEventType.keyError => Icons.key_off_outlined,
      SecurityEventType.rollbackDetected => Icons.restore_page_outlined,
      SecurityEventType.vaultOpened => Icons.lock_open_outlined,
      SecurityEventType.vaultSealed => Icons.enhanced_encryption_outlined,
    };
  }

  String _labelFor(SecurityEventType type) {
    return switch (type) {
      SecurityEventType.authSuccess => 'Authentication success',
      SecurityEventType.authFailure => 'Authentication failure',
      SecurityEventType.lockdown => 'Lockdown',
      SecurityEventType.vaultLock => 'Vault lock',
      SecurityEventType.keyError => 'Key error',
      SecurityEventType.rollbackDetected => 'Rollback detected',
      SecurityEventType.vaultOpened => 'Vault opened',
      SecurityEventType.vaultSealed => 'Vault sealed',
    };
  }
}
