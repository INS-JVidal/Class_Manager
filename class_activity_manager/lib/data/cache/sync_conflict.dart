/// Types of sync conflicts that can occur during optimistic locking.
enum SyncConflictType {
  /// No conflict.
  none,

  /// Server has a newer version than the local update.
  versionMismatch,

  /// Entity was deleted on server while local had pending changes.
  deleted,
}

/// Represents a sync conflict detected during synchronization.
class SyncConflict {
  const SyncConflict({
    required this.entityType,
    required this.entityId,
    required this.type,
    this.serverDocument,
  });

  /// The type of entity (e.g., 'modul', 'group', 'dailyNote').
  final String entityType;

  /// The ID of the conflicting entity.
  final String entityId;

  /// The type of conflict detected.
  final SyncConflictType type;

  /// The current server document (for version mismatch conflicts).
  final Map<String, dynamic>? serverDocument;
}

/// Exception thrown when a sync conflict is detected.
class ConflictException implements Exception {
  const ConflictException({
    required this.type,
    required this.entityType,
    required this.entityId,
    this.serverDocument,
  });

  final SyncConflictType type;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? serverDocument;

  @override
  String toString() => 'ConflictException: $type for $entityType/$entityId';
}
