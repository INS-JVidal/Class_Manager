import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'audit_logger.dart';

/// Resolves the XDG state directory for audit logs on Linux.
/// Returns null on non-Linux or when HOME is not set.
String? resolveAuditLogDirectory() {
  if (!Platform.isLinux) return null;
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) return null;
  final base = Platform.environment['XDG_STATE_HOME'] ?? '$home/.local/state';
  return '$base/class_activity_manager';
}

/// Writes audit events to a file under [logDirectory]. One line per event,
/// flushed immediately. No in-memory storage of logs.
class FileAuditLogger implements AuditLogger {
  FileAuditLogger(String logDirectory) {
    try {
      final dir = Directory(logDirectory);

      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('$logDirectory/audit.log');
      _sink = file.openWrite(mode: FileMode.append);
    } catch (e) {
      debugPrint('FileAuditLogger: failed to open audit log: $e');
      _sink = null;
    }
  }

  IOSink? _sink;

  @override
  void log(
    String operation,
    String phase,
    Map<String, dynamic> payload, {
    String? traceId,
  }) {
    final sink = _sink;

    if (sink == null) return;

    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final payloadStr = jsonEncode(payload);
      final line =
          '$timestamp\t$operation\t$phase\t$payloadStr\t${traceId ?? ''}\n';
      sink.write(line);
      // Don't call flush() - OS buffers writes, flushes on close
    } catch (e) {
      debugPrint('FileAuditLogger: write failed: $e');
    }
  }

  /// Closes the log file. Optional; OS will close on process exit if not called.
  void close() {
    _sink?.close();
    _sink = null;
  }
}
