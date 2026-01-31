import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../cache/schemas/schemas.dart';

/// Local Isar datasource for offline caching.
class LocalDatasource {
  Isar? _isar;

  bool get isInitialized => _isar != null;

  Isar get db {
    final isar = _isar;
    if (isar == null) {
      throw StateError(
        'LocalDatasource not initialized. Call initialize() first.',
      );
    }
    return isar;
  }

  Future<void> initialize() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/class_activity_manager';

    // Ensure the directory exists
    final dbDir = Directory(dbPath);
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    _isar = await Isar.open([
      ModulCacheSchema,
      GroupCacheSchema,
      DailyNoteCacheSchema,
      AcademicYearCacheSchema,
      RecurringHolidayCacheSchema,
      SyncOperationSchema,
    ], directory: dbPath);
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  Future<void> clear() async {
    final isar = db;
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
