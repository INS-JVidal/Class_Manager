import 'package:class_activity_manager/core/audit/audit_logger.dart';

/// Test logger that records events in memory for assertions.
class TestAuditLogger implements AuditLogger {
  final List<AuditEvent> _events = [];

  List<AuditEvent> get events => List.unmodifiable(_events);

  void clear() => _events.clear();

  @override
  void log(
    String operation,
    String phase,
    Map<String, dynamic> payload, {
    String? traceId,
  }) {
    _events.add(AuditEvent(
      operation: operation,
      phase: phase,
      payload: Map<String, dynamic>.from(payload),
      traceId: traceId,
    ));
  }
}
