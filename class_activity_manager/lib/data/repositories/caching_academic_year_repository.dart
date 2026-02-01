import 'dart:convert';

import 'package:isar/isar.dart';

import '../../models/academic_year.dart';
import '../../models/vacation_period.dart';
import '../cache/schemas/academic_year_cache.dart';
import '../cache/schemas/sync_operation.dart';
import 'base_caching_repository.dart';

/// Caching repository for AcademicYear with local-first persistence.
///
/// Extends [BaseCachingRepository] to inherit common CRUD operations
/// with automatic sync queue management.
class CachingAcademicYearRepository
    extends BaseCachingRepository<AcademicYear, AcademicYearCache> {
  CachingAcademicYearRepository(super.local, super.queue);

  @override
  String get entityType => 'academicYear';

  @override
  IsarCollection<AcademicYearCache> get collection =>
      local.db.academicYearCaches;

  @override
  Future<AcademicYearCache?> findCacheById(String id) async {
    return collection.filter().idEqualTo(id).findFirst();
  }

  @override
  Id getIsarId(AcademicYearCache cache) => cache.isarId;

  @override
  void setIsarId(AcademicYearCache cache, Id isarId) => cache.isarId = isarId;

  @override
  Map<String, dynamic> toJson(AcademicYear entity) => entity.toJson();

  @override
  String getId(AcademicYear entity) => entity.id;

  @override
  AcademicYear toEntity(AcademicYearCache cache) {
    return AcademicYear(
      id: cache.id,
      name: cache.name,
      startDate: cache.startDate,
      endDate: cache.endDate,
      vacationPeriods: _decodeVacationPeriods(cache.vacationPeriodsJson),
      isActive: cache.isActive,
      version: cache.version,
    );
  }

  @override
  AcademicYearCache toCache(AcademicYear year, {bool pendingSync = true}) {
    return AcademicYearCache()
      ..id = year.id
      ..name = year.name
      ..startDate = year.startDate
      ..endDate = year.endDate
      ..vacationPeriodsJson = jsonEncode(
        year.vacationPeriods.map((vp) => vp.toJson()).toList(),
      )
      ..isActive = year.isActive
      ..version = year.version
      ..lastModified = DateTime.now()
      ..pendingSync = pendingSync;
  }

  // --- Entity-specific queries ---

  Future<AcademicYear?> findActive() async {
    final cached = await collection.filter().isActiveEqualTo(true).findFirst();
    return cached != null ? toEntity(cached) : null;
  }

  Future<void> setActiveYear(String yearId) async {
    await local.db.writeTxn(() async {
      // Deactivate all
      final allYears = await collection.where().findAll();
      for (final year in allYears) {
        if (year.id != yearId && year.isActive) {
          year.isActive = false;
          year.lastModified = DateTime.now();
          await collection.put(year);
        } else if (year.id == yearId && !year.isActive) {
          year.isActive = true;
          year.lastModified = DateTime.now();
          await collection.put(year);
        }
      }
    });

    // Queue sync for all years (to update isActive flag remotely)
    final allYears = await findAll();
    for (final year in allYears) {
      await queue.enqueue(
        entityType: 'academicYear',
        entityId: year.id,
        operation: SyncOperationType.update,
        payload: year.toJson(),
      );
    }
  }

  // --- Private helpers ---

  List<VacationPeriod> _decodeVacationPeriods(String json) {
    if (json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List<dynamic>) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((vp) => VacationPeriod.fromJson(vp))
          .toList();
    } on FormatException {
      // Corrupted cache data - return empty list rather than crash
      return [];
    }
  }
}
