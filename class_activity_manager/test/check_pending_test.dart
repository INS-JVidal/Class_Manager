// Run with: flutter test test/check_pending_test.dart
@Tags(['check-pending'])
library;

import 'package:class_activity_manager/data/cache/schemas/schemas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  test('Check pending sync operations', () async {
    await Isar.initializeIsarCore(download: true);

    final dbPath = '/home/jvidal/Documents/OPOS/class_activity_manager';

    print('Checking Isar database at: $dbPath');

    final isar = await Isar.open(
      [
        ModulCacheSchema,
        GroupCacheSchema,
        DailyNoteCacheSchema,
        AcademicYearCacheSchema,
        RecurringHolidayCacheSchema,
        SyncOperationSchema,
        UserPreferencesCacheSchema,
      ],
      directory: dbPath,
      name: 'default',
    );

    final pending = await isar.syncOperations.where().findAll();

    print('\n${'=' * 60}');
    print('PENDING SYNC OPERATIONS: ${pending.length}');
    print('${'=' * 60}\n');

    if (pending.isEmpty) {
      print('✓ No pending operations. Safe to reset local database.');
    } else {
      for (final op in pending) {
        print('Type: ${op.operationType}');
        print('Entity: ${op.entityType} / ${op.entityId}');
        print('Timestamp: ${op.timestamp}');
        print('Retries: ${op.retryCount}');

        if (op.lastError != null) {
          print('Last Error: ${op.lastError}');
        }

        print(
          'Payload preview: ${op.payload.substring(0, op.payload.length.clamp(0, 100))}...',
        );
        print('-' * 40);
      }
    }

    await isar.close();
  });
}
