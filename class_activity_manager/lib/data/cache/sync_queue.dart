import 'dart:convert';

import 'package:isar/isar.dart';

import '../datasources/local_datasource.dart';
import 'schemas/sync_operation.dart';

/// Queue for pending sync operations.
class SyncQueue {
  SyncQueue(this._local);

  final LocalDatasource _local;

  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required SyncOperationType operation,
    required Map<String, dynamic> payload,
  }) async {
    await _local.db.writeTxn(() async {
      // Find any existing pending operation for this entity
      final existing = await _local.db.syncOperations
          .filter()
          .entityTypeEqualTo(entityType)
          .and()
          .entityIdEqualTo(entityId)
          .findAll();

      // If the existing pending op is an insert and the new op is an update,
      // keep the operation type as insert so the server receives a create.
      var effectiveOperation = operation;
      for (final old in existing) {
        if (old.operationType == 'insert' &&
            operation == SyncOperationType.update) {
          effectiveOperation = SyncOperationType.insert;
        }
        await _local.db.syncOperations.delete(old.id);
      }

      final op = SyncOperation()
        ..entityType = entityType
        ..entityId = entityId
        ..operationType = effectiveOperation.name
        ..payload = jsonEncode(payload)
        ..timestamp = DateTime.now()
        ..retryCount = 0;

      // Add the new operation with latest data
      await _local.db.syncOperations.put(op);
    });
  }

  Future<List<SyncOperation>> getPending() async {
    return _local.db.syncOperations.where().sortByTimestamp().findAll();
  }

  Future<void> remove(Id id) async {
    await _local.db.writeTxn(() async {
      await _local.db.syncOperations.delete(id);
    });
  }

  Future<void> markFailed(Id id, String error) async {
    final op = await _local.db.syncOperations.get(id);
    if (op != null) {
      op.retryCount++;
      op.lastError = error;
      await _local.db.writeTxn(() async {
        await _local.db.syncOperations.put(op);
      });
    }
  }

  Future<int> get pendingCount async {
    return _local.db.syncOperations.count();
  }

  Future<void> clear() async {
    await _local.db.writeTxn(() async {
      await _local.db.syncOperations.clear();
    });
  }
}
