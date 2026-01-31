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
    final op = SyncOperation()
      ..entityType = entityType
      ..entityId = entityId
      ..operationType = operation.name
      ..payload = jsonEncode(payload)
      ..timestamp = DateTime.now()
      ..retryCount = 0;

    await _local.db.writeTxn(() async {
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
