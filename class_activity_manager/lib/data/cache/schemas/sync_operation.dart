import 'package:isar/isar.dart';

part 'sync_operation.g.dart';

/// Isar schema for pending sync operations.
@collection
class SyncOperation {
  Id id = Isar.autoIncrement;

  @Index()
  late String entityType;

  late String entityId;
  late String operationType;

  /// JSON payload of the entity.
  late String payload;

  @Index()
  late DateTime timestamp;

  late int retryCount;
  String? lastError;
}

/// Type of sync operation.
enum SyncOperationType { insert, update, delete }
