import 'dart:convert';

import 'package:isar/isar.dart';

import '../../models/academic_year.dart';
import '../../models/vacation_period.dart';
import '../cache/schemas/academic_year_cache.dart';
import '../cache/schemas/sync_operation.dart';
import '../cache/sync_queue.dart';
import '../datasources/local_datasource.dart';

/// Caching repository for AcademicYear with local-first persistence.
class CachingAcademicYearRepository {
  CachingAcademicYearRepository(this._local, this._queue);

  final LocalDatasource _local;
  final SyncQueue _queue;

  IsarCollection<AcademicYearCache> get _collection =>
      _local.db.academicYearCaches;

  Future<List<AcademicYear>> findAll() async {
    final cached = await _collection.where().findAll();
    return cached.map(_toYear).toList();
  }

  Future<AcademicYear?> findById(String id) async {
    final cached = await _collection.filter().idEqualTo(id).findFirst();
    return cached != null ? _toYear(cached) : null;
  }

  Future<AcademicYear> insert(AcademicYear year) async {
    await _local.db.writeTxn(() async {
      await _collection.put(_toCache(year));
    });

    await _queue.enqueue(
      entityType: 'academicYear',
      entityId: year.id,
      operation: SyncOperationType.insert,
      payload: year.toJson(),
    );

    return year;
  }

  Future<AcademicYear> update(AcademicYear year) async {
    final existing = await _collection.filter().idEqualTo(year.id).findFirst();
    final cache = _toCache(year);
    if (existing != null) {
      cache.isarId = existing.isarId;
    }

    await _local.db.writeTxn(() async {
      await _collection.put(cache);
    });

    await _queue.enqueue(
      entityType: 'academicYear',
      entityId: year.id,
      operation: SyncOperationType.update,
      payload: year.toJson(),
    );

    return year;
  }

  Future<void> delete(String id) async {
    final existing = await _collection.filter().idEqualTo(id).findFirst();

    if (existing != null) {
      await _local.db.writeTxn(() async {
        await _collection.delete(existing.isarId);
      });
    }

    await _queue.enqueue(
      entityType: 'academicYear',
      entityId: id,
      operation: SyncOperationType.delete,
      payload: {'_id': id},
    );
  }

  Future<AcademicYear?> findActive() async {
    final cached = await _collection.filter().isActiveEqualTo(true).findFirst();
    return cached != null ? _toYear(cached) : null;
  }

  Future<void> setActiveYear(String yearId) async {
    await _local.db.writeTxn(() async {
      // Deactivate all
      final allYears = await _collection.where().findAll();
      for (final year in allYears) {
        if (year.id != yearId && year.isActive) {
          year.isActive = false;
          year.lastModified = DateTime.now();
          await _collection.put(year);
        } else if (year.id == yearId && !year.isActive) {
          year.isActive = true;
          year.lastModified = DateTime.now();
          await _collection.put(year);
        }
      }
    });

    // Queue sync for all years (to update isActive flag remotely)
    final allYears = await findAll();
    for (final year in allYears) {
      await _queue.enqueue(
        entityType: 'academicYear',
        entityId: year.id,
        operation: SyncOperationType.update,
        payload: year.toJson(),
      );
    }
  }

  Future<void> syncFromRemote(List<AcademicYear> years) async {
    await _local.db.writeTxn(() async {
      await _collection.clear();
      for (final year in years) {
        await _collection.put(_toCache(year, pendingSync: false));
      }
    });
  }

  AcademicYear _toYear(AcademicYearCache cache) {
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

  AcademicYearCache _toCache(AcademicYear year, {bool pendingSync = true}) {
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

  List<VacationPeriod> _decodeVacationPeriods(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((vp) => VacationPeriod.fromJson(vp as Map<String, dynamic>))
        .toList();
  }
}
