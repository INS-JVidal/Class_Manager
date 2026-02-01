import 'package:isar/isar.dart';

import '../../models/recurring_holiday.dart';
import '../cache/schemas/recurring_holiday_cache.dart';
import 'base_caching_repository.dart';

/// Caching repository for RecurringHoliday with local-first persistence.
///
/// Extends [BaseCachingRepository] to inherit common CRUD operations
/// with automatic sync queue management.
class CachingRecurringHolidayRepository
    extends BaseCachingRepository<RecurringHoliday, RecurringHolidayCache> {
  CachingRecurringHolidayRepository(super.local, super.queue);

  @override
  String get entityType => 'recurringHoliday';

  @override
  IsarCollection<RecurringHolidayCache> get collection =>
      local.db.recurringHolidayCaches;

  @override
  Future<RecurringHolidayCache?> findCacheById(String id) async {
    return collection.filter().idEqualTo(id).findFirst();
  }

  @override
  Id getIsarId(RecurringHolidayCache cache) => cache.isarId;

  @override
  void setIsarId(RecurringHolidayCache cache, Id isarId) =>
      cache.isarId = isarId;

  @override
  Map<String, dynamic> toJson(RecurringHoliday entity) => entity.toJson();

  @override
  String getId(RecurringHoliday entity) => entity.id;

  @override
  RecurringHoliday toEntity(RecurringHolidayCache cache) {
    return RecurringHoliday(
      id: cache.id,
      name: cache.name,
      month: cache.month,
      day: cache.day,
      isEnabled: cache.isEnabled,
      version: cache.version,
    );
  }

  @override
  RecurringHolidayCache toCache(
    RecurringHoliday holiday, {
    bool pendingSync = true,
  }) {
    return RecurringHolidayCache()
      ..id = holiday.id
      ..name = holiday.name
      ..month = holiday.month
      ..day = holiday.day
      ..isEnabled = holiday.isEnabled
      ..version = holiday.version
      ..lastModified = DateTime.now()
      ..pendingSync = pendingSync;
  }

  // --- Entity-specific queries ---

  Future<List<RecurringHoliday>> findEnabled() async {
    final cached = await collection.filter().isEnabledEqualTo(true).findAll();
    return cached.map(toEntity).toList();
  }
}
