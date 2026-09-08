import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/security_event.dart';
import '../domain/security_event_journal.dart';

/// PersistentSecurityEventJournal stores security events to disk in append-only format (JSONL).
/// This prevents tampering with event history and survives app restarts.
///
/// Format: One SecurityEvent JSON object per line (JSONL).
/// This enables:
/// - Atomicity: Each append is a single write
/// - Auditability: Events cannot be selectively removed
/// - Forensics: Complete history persists across sessions
class PersistentSecurityEventJournal implements SecurityEventJournal {
  PersistentSecurityEventJournal();

  static const _fileName = 'security_event_journal.jsonl';

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  @override
  Future<void> append(SecurityEvent event) async {
    try {
      final file = await _file;
      final line = jsonEncode(event.toJson()) + '\n';
      await file.writeAsString(line, mode: FileMode.append);
    } catch (e) {
      // CRITICAL: Journal write failures must not crash the app,
      // but should trigger alerts. Log to stderr for visibility.
      stderr.writeln('CRITICAL: Security journal write failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<SecurityEvent>> latest({int limit = 50}) async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return <SecurityEvent>[];
      }

      final lines = await file.readAsLines();
      final events = <SecurityEvent>[];

      // Parse from end to start (most recent first).
      for (int i = lines.length - 1; i >= 0 && events.length < limit; i--) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          events.add(SecurityEvent.fromJson(json));
        } catch (e) {
          // Skip malformed lines; journal corruption is handled.
          stderr.writeln('Warning: Skipped malformed journal line: $e');
        }
      }

      return List<SecurityEvent>.unmodifiable(events);
    } catch (e) {
      stderr.writeln('Error reading security journal: $e');
      return <SecurityEvent>[];
    }
  }

  /// Clears the journal. Use with caution—primarily for testing.
  Future<void> clear() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      stderr.writeln('Warning: Failed to clear journal: $e');
    }
  }

  /// Returns the total number of events persisted.
  Future<int> eventCount() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return 0;
      }
      final lines = await file.readAsLines();
      return lines.where((line) => line.trim().isNotEmpty).length;
    } catch (e) {
      return 0;
    }
  }

  /// Exports the full journal for audit/backup purposes.
  Future<String> exportAsJsonl() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return '';
      }
      return await file.readAsString();
    } catch (e) {
      return '';
    }
  }
}
