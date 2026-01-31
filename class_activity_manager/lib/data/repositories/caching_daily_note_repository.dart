import 'package:isar/isar.dart';

import '../../models/daily_note.dart';
import '../cache/schemas/daily_note_cache.dart';
import '../cache/schemas/sync_operation.dart';
import '../cache/sync_queue.dart';
import '../datasources/local_datasource.dart';

/// Caching repository for DailyNote with local-first persistence.
class CachingDailyNoteRepository {
  CachingDailyNoteRepository(this._local, this._queue);

  final LocalDatasource _local;
  final SyncQueue _queue;

  IsarCollection<DailyNoteCache> get _collection => _local.db.dailyNoteCaches;

  Future<List<DailyNote>> findAll() async {
    final cached = await _collection.where().findAll();
    return cached.map(_toNote).toList();
  }

  Future<DailyNote?> findById(String id) async {
    final cached = await _collection.filter().idEqualTo(id).findFirst();
    return cached != null ? _toNote(cached) : null;
  }

  Future<DailyNote> insert(DailyNote note) async {
    await _local.db.writeTxn(() async {
      await _collection.put(_toCache(note));
    });

    await _queue.enqueue(
      entityType: 'dailyNote',
      entityId: note.id,
      operation: SyncOperationType.insert,
      payload: note.toJson(),
    );

    return note;
  }

  Future<DailyNote> update(DailyNote note) async {
    final existing = await _collection.filter().idEqualTo(note.id).findFirst();
    final cache = _toCache(note);
    if (existing != null) {
      cache.isarId = existing.isarId;
    }

    await _local.db.writeTxn(() async {
      await _collection.put(cache);
    });

    await _queue.enqueue(
      entityType: 'dailyNote',
      entityId: note.id,
      operation: SyncOperationType.update,
      payload: note.toJson(),
    );

    return note;
  }

  Future<void> delete(String id) async {
    final existing = await _collection.filter().idEqualTo(id).findFirst();

    if (existing != null) {
      await _local.db.writeTxn(() async {
        await _collection.delete(existing.isarId);
      });
    }

    await _queue.enqueue(
      entityType: 'dailyNote',
      entityId: id,
      operation: SyncOperationType.delete,
      payload: {'_id': id},
    );
  }

  Future<List<DailyNote>> findByGroupAndModule(
    String groupId,
    String modulId,
  ) async {
    final cached = await _collection
        .filter()
        .groupIdEqualTo(groupId)
        .and()
        .modulIdEqualTo(modulId)
        .findAll();
    return cached.map(_toNote).toList();
  }

  Future<List<DailyNote>> findByRaId(String raId) async {
    final cached = await _collection.filter().raIdEqualTo(raId).findAll();
    return cached.map(_toNote).toList();
  }

  Future<DailyNote?> findByGroupRaDate(
    String groupId,
    String raId,
    DateTime date,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final cached = await _collection
        .filter()
        .groupIdEqualTo(groupId)
        .and()
        .raIdEqualTo(raId)
        .and()
        .dateBetween(dayStart, dayEnd, includeUpper: false)
        .findFirst();

    return cached != null ? _toNote(cached) : null;
  }

  Future<List<DailyNote>> findByGroupRa(String groupId, String raId) async {
    final cached = await _collection
        .filter()
        .groupIdEqualTo(groupId)
        .and()
        .raIdEqualTo(raId)
        .findAll();
    return cached.map(_toNote).toList();
  }

  Future<void> syncFromRemote(List<DailyNote> notes) async {
    await _local.db.writeTxn(() async {
      await _collection.clear();
      for (final note in notes) {
        await _collection.put(_toCache(note, pendingSync: false));
      }
    });
  }

  DailyNote _toNote(DailyNoteCache cache) {
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

  DailyNoteCache _toCache(DailyNote note, {bool pendingSync = true}) {
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
}
