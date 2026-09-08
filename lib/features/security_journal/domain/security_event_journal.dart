import 'security_event.dart';

abstract interface class SecurityEventJournal {
  Future<void> append(SecurityEvent event);
  Future<List<SecurityEvent>> latest({int limit = 50});
}

class InMemorySecurityEventJournal implements SecurityEventJournal {
  final List<SecurityEvent> _events = <SecurityEvent>[];

  @override
  Future<void> append(SecurityEvent event) async {
    _events.insert(0, event);
  }

  @override
  Future<List<SecurityEvent>> latest({int limit = 50}) async {
    return List<SecurityEvent>.unmodifiable(_events.take(limit));
  }
}
