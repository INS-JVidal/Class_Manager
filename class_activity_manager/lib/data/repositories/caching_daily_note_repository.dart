import 'package:isar/isar.dart';

import '../../models/daily_note.dart';
import '../cache/schemas/daily_note_cache.dart';
import 'base_caching_repository.dart';

/// Caching repository for DailyNote with local-first persistence.
///
/// Extends [BaseCachingRepository] to inherit common CRUD operations
/// with automatic sync queue management.
class CachingDailyNoteRepository
    extends BaseCachingRepository<DailyNote, DailyNoteCache> {
  CachingDailyNoteRepository(super.local, super.queue);

  @override
  String get entityType => 'dailyNote';

  @override
  IsarCollection<DailyNoteCache> get collection => local.db.dailyNoteCaches;

  @override
  Future<DailyNoteCache?> findCacheById(String id) async {
    return collection.filter().idEqualTo(id).findFirst();
  }

  @override
  Id getIsarId(DailyNoteCache cache) => cache.isarId;

  @override
  void setIsarId(DailyNoteCache cache, Id isarId) => cache.isarId = isarId;

  @override
  Map<String, dynamic> toJson(DailyNote entity) => entity.toJson();

  @override
  String getId(DailyNote entity) => entity.id;

  @override
  DailyNote toEntity(DailyNoteCache cache) {
    return DailyNote(
      id: cache.id,
      raId: cache.raId,
      modulId: cache.modulId,
      groupId: cache.groupId,
      date: cache.date,
      plannedContent: cache.plannedContent,
      actualContent: cache.actualContent,
      notes: cache.notes,
      completed: cache.completed,
      version: cache.version,
    );
  }

  @override
  DailyNoteCache toCache(DailyNote note, {bool pendingSync = true}) {
    return DailyNoteCache()
      ..id = note.id
      ..raId = note.raId
      ..modulId = note.modulId
      ..groupId = note.groupId
      ..date = DateTime(note.date.year, note.date.month, note.date.day)
      ..plannedContent = note.plannedContent
      ..actualContent = note.actualContent
      ..notes = note.notes
      ..completed = note.completed
      ..version = note.version
      ..lastModified = DateTime.now()
      ..pendingSync = pendingSync;
  }

  // --- Entity-specific queries ---

  Future<List<DailyNote>> findByGroupAndModule(
    String groupId,
    String modulId,
  ) async {
    final cached = await collection
        .filter()
        .groupIdEqualTo(groupId)
        .and()
        .modulIdEqualTo(modulId)
        .findAll();
    return cached.map(toEntity).toList();
  }

  Future<List<DailyNote>> findByRaId(String raId) async {
    final cached = await collection.filter().raIdEqualTo(raId).findAll();
    return cached.map(toEntity).toList();
  }

  Future<DailyNote?> findByGroupRaDate(
    String groupId,
    String raId,
    DateTime date,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final cached = await collection
        .filter()
        .groupIdEqualTo(groupId)
        .and()
        .raIdEqualTo(raId)
        .and()
        .dateBetween(dayStart, dayEnd, includeUpper: false)
        .findFirst();

    return cached != null ? toEntity(cached) : null;
  }

  Future<List<DailyNote>> findByGroupRa(String groupId, String raId) async {
    final cached = await collection
        .filter()
        .groupIdEqualTo(groupId)
        .and()
        .raIdEqualTo(raId)
        .findAll();
    return cached.map(toEntity).toList();
  }
}
