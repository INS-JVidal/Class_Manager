import 'package:flutter/foundation.dart';

/// Immutable record of a single audit event for tracing and tests.
class AuditEvent {
  AuditEvent({
    required this.operation,
    required this.phase,
    required this.payload,
    this.traceId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String operation;
  final String phase;
  final Map<String, dynamic> payload;
  final String? traceId;
  final DateTime timestamp;

  @override
  String toString() =>
      'AuditEvent($operation|$phase|traceId=$traceId|$payload)';
}

/// Audit-style logger: operation, phase (started/action/completed/failed), payload, optional traceId.
abstract class AuditLogger {
  void log(
    String operation,
    String phase,
    Map<String, dynamic> payload, {
    String? traceId,
  });
}

/// Production logger: single-line debugPrint.
class DefaultAuditLogger implements AuditLogger {
  @override
  void log(
    String operation,
    String phase,
    Map<String, dynamic> payload, {
    String? traceId,
  }) {
    final parts = [operation, phase];
    if (traceId != null) parts.add('traceId=$traceId');
    parts.add(payload.toString());
    debugPrint('[Audit] ${parts.join(' | ')}');
  }
}

/// No-op logger for disabling audit in production.
class NoOpAuditLogger implements AuditLogger {
  @override
  void log(
    String operation,
    String phase,
    Map<String, dynamic> payload, {
    String? traceId,
  }) {}
}
