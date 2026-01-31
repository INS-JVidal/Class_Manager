import 'package:isar/isar.dart';

import '../../models/recurring_holiday.dart';
import '../cache/schemas/recurring_holiday_cache.dart';
import '../cache/schemas/sync_operation.dart';
import '../cache/sync_queue.dart';
import '../datasources/local_datasource.dart';

/// Caching repository for RecurringHoliday with local-first persistence.
class CachingRecurringHolidayRepository {
  CachingRecurringHolidayRepository(this._local, this._queue);

  final LocalDatasource _local;
  final SyncQueue _queue;

  IsarCollection<RecurringHolidayCache> get _collection =>
      _local.db.recurringHolidayCaches;

  Future<List<RecurringHoliday>> findAll() async {
    final cached = await _collection.where().findAll();
    return cached.map(_toHoliday).toList();
  }

  Future<RecurringHoliday?> findById(String id) async {
    final cached = await _collection.filter().idEqualTo(id).findFirst();
    return cached != null ? _toHoliday(cached) : null;
  }

  Future<RecurringHoliday> insert(RecurringHoliday holiday) async {
    await _local.db.writeTxn(() async {
      await _collection.put(_toCache(holiday));
    });

    await _queue.enqueue(
      entityType: 'recurringHoliday',
      entityId: holiday.id,
      operation: SyncOperationType.insert,
      payload: holiday.toJson(),
    );

    return holiday;
  }

  Future<RecurringHoliday> update(RecurringHoliday holiday) async {
    final existing = await _collection
        .filter()
        .idEqualTo(holiday.id)
        .findFirst();
    final cache = _toCache(holiday);
    if (existing != null) {
      cache.isarId = existing.isarId;
    }

    await _local.db.writeTxn(() async {
      await _collection.put(cache);
    });

    await _queue.enqueue(
      entityType: 'recurringHoliday',
      entityId: holiday.id,
      operation: SyncOperationType.update,
      payload: holiday.toJson(),
    );

    return holiday;
  }

  Future<void> delete(String id) async {
    final existing = await _collection.filter().idEqualTo(id).findFirst();

    if (existing != null) {
      await _local.db.writeTxn(() async {
        await _collection.delete(existing.isarId);
      });
    }

    await _queue.enqueue(
      entityType: 'recurringHoliday',
      entityId: id,
      operation: SyncOperationType.delete,
      payload: {'_id': id},
    );
  }

  Future<List<RecurringHoliday>> findEnabled() async {
    final cached = await _collection.filter().isEnabledEqualTo(true).findAll();
    return cached.map(_toHoliday).toList();
  }

  Future<void> syncFromRemote(List<RecurringHoliday> holidays) async {
    await _local.db.writeTxn(() async {
      await _collection.clear();
      for (final holiday in holidays) {
        await _collection.put(_toCache(holiday, pendingSync: false));
      }
    });
  }

  RecurringHoliday _toHoliday(RecurringHolidayCache cache) {
    return RecurringHoliday(
      id: cache.id,
      name: cache.name,
      month: cache.month,
      day: cache.day,
      isEnabled: cache.isEnabled,
    );
  }

  RecurringHolidayCache _toCache(
    RecurringHoliday holiday, {
    bool pendingSync = true,
  }) {
    return RecurringHolidayCache()
      ..id = holiday.id
      ..name = holiday.name
      ..month = holiday.month
      ..day = holiday.day
      ..isEnabled = holiday.isEnabled
      ..lastModified = DateTime.now()
      ..pendingSync = pendingSync;
  }
}
