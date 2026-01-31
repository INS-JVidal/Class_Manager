import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:class_activity_manager/app.dart';
import 'package:class_activity_manager/data/cache/schemas/schemas.dart';
import 'package:class_activity_manager/data/cache/sync_queue.dart';
import 'package:class_activity_manager/data/datasources/local_datasource.dart';
import 'package:class_activity_manager/data/datasources/mongodb_datasource.dart';
import 'package:class_activity_manager/data/services/cache_service.dart';
import 'package:class_activity_manager/state/providers.dart';

/// Test-friendly CacheService that uses in-memory Isar.
class TestCacheService extends CacheService {
  TestCacheService(super.local, super.remote, super.queue);

  @override
  Future<void> triggerSync() async {
    // No-op for tests
  }
}

/// Test-friendly LocalDatasource with in-memory Isar.
class TestLocalDatasource extends LocalDatasource {
  Isar? _testIsar;

  @override
  bool get isInitialized => _testIsar != null;

  @override
  Isar get db {
    final isar = _testIsar;
    if (isar == null) {
      throw StateError('TestLocalDatasource not initialized');
    }
    return isar;
  }

  @override
  Future<void> initialize() async {
    if (_testIsar != null) return;

    await Isar.initializeIsarCore(download: true);
    _testIsar = await Isar.open([
      ModulCacheSchema,
      GroupCacheSchema,
      DailyNoteCacheSchema,
      AcademicYearCacheSchema,
      RecurringHolidayCacheSchema,
      SyncOperationSchema,
    ], directory: '');
  }

  @override
  Future<void> close() async {
    await _testIsar?.close();
    _testIsar = null;
  }
}

void main() {
  late TestLocalDatasource localDatasource;
  late MongoDbDatasource mongoDatasource;
  late SyncQueue syncQueue;
  late TestCacheService cacheService;

  setUpAll(() async {
    localDatasource = TestLocalDatasource();
    await localDatasource.initialize();
    mongoDatasource = MongoDbDatasource();
    syncQueue = SyncQueue(localDatasource);
    cacheService = TestCacheService(
      localDatasource,
      mongoDatasource,
      syncQueue,
    );
  });

  tearDownAll(() async {
    await localDatasource.close();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localDatasourceProvider.overrideWithValue(localDatasource),
          syncQueueProvider.overrideWithValue(syncQueue),
          cacheServiceProvider.overrideWithValue(cacheService),
        ],
        child: const ClassActivityManagerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Class Activity Manager'), findsOneWidget);
  });
}
