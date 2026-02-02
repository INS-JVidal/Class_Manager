// Script to check pending sync operations in the local Isar database.
// Run with: dart run scripts/check_pending_sync.dart

import 'dart:io';

import 'package:class_activity_manager/data/cache/schemas/schemas.dart';
import 'package:isar/isar.dart';

void main() async {
  final dbPath = Directory.current.path;

  print('Checking Isar database at: $dbPath');

  final isar = await Isar.open([
    ModulCacheSchema,
    GroupCacheSchema,
    DailyNoteCacheSchema,
    AcademicYearCacheSchema,
    RecurringHolidayCacheSchema,
    SyncOperationSchema,
    UserPreferencesCacheSchema,
  ], directory: dbPath);

  final pending = await isar.syncOperations.where().findAll();

  print('\n${'=' * 60}');
  print('PENDING SYNC OPERATIONS: ${pending.length}');
  print('${'=' * 60}\n');

  if (pending.isEmpty) {
    print('No pending operations. Safe to reset local database.');
  } else {
    for (final op in pending) {
      print('Type: ${op.operationType}');
      print('Entity: ${op.entityType} / ${op.entityId}');
      print('Timestamp: ${op.timestamp}');
      print('Retries: ${op.retryCount}');

      if (op.lastError != null) {
        print('Last Error: ${op.lastError}');
      }

      print('Payload: ${op.payload}');
      print('-' * 40);
    }
  }

  await isar.close();
}
