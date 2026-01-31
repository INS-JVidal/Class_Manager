import 'package:isar/isar.dart';

import '../../models/group.dart';
import '../cache/schemas/group_cache.dart';
import '../cache/schemas/sync_operation.dart';
import '../cache/sync_queue.dart';
import '../datasources/local_datasource.dart';

/// Caching repository for Group with local-first persistence.
class CachingGroupRepository {
  CachingGroupRepository(this._local, this._queue);

  final LocalDatasource _local;
  final SyncQueue _queue;

  IsarCollection<GroupCache> get _collection => _local.db.groupCaches;

  Future<List<Group>> findAll() async {
    final cached = await _collection.where().findAll();
    return cached.map(_toGroup).toList();
  }

  Future<Group?> findById(String id) async {
    final cached = await _collection.filter().idEqualTo(id).findFirst();
    return cached != null ? _toGroup(cached) : null;
  }

  Future<Group> insert(Group group) async {
    await _local.db.writeTxn(() async {
      await _collection.put(_toCache(group));
    });

    await _queue.enqueue(
      entityType: 'group',
      entityId: group.id,
      operation: SyncOperationType.insert,
      payload: group.toJson(),
    );

    return group;
  }

  Future<Group> update(Group group) async {
    final existing = await _collection.filter().idEqualTo(group.id).findFirst();
    final cache = _toCache(group);
    if (existing != null) {
      cache.isarId = existing.isarId;
    }

    await _local.db.writeTxn(() async {
      await _collection.put(cache);
    });

    await _queue.enqueue(
      entityType: 'group',
      entityId: group.id,
      operation: SyncOperationType.update,
      payload: group.toJson(),
    );

    return group;
  }

  Future<void> delete(String id) async {
    final existing = await _collection.filter().idEqualTo(id).findFirst();

    if (existing != null) {
      await _local.db.writeTxn(() async {
        await _collection.delete(existing.isarId);
      });
    }

    await _queue.enqueue(
      entityType: 'group',
      entityId: id,
      operation: SyncOperationType.delete,
      payload: {'_id': id},
    );
  }

  Future<List<Group>> findByAcademicYear(String academicYearId) async {
    final cached = await _collection
        .filter()
        .academicYearIdEqualTo(academicYearId)
        .findAll();
    return cached.map(_toGroup).toList();
  }

  Future<void> syncFromRemote(List<Group> groups) async {
    await _local.db.writeTxn(() async {
      await _collection.clear();
      for (final group in groups) {
        await _collection.put(_toCache(group, pendingSync: false));
      }
    });
  }

  Group _toGroup(GroupCache cache) {
    return Group(
      id: cache.id,
      name: cache.name,
      notes: cache.notes,
      academicYearId: cache.academicYearId,
      moduleIds: cache.moduleIds,
      color: cache.color,
    );
  }

  GroupCache _toCache(Group group, {bool pendingSync = true}) {
    return GroupCache()
      ..id = group.id
      ..name = group.name
      ..notes = group.notes
      ..academicYearId = group.academicYearId
      ..moduleIds = group.moduleIds
      ..color = group.color
      ..lastModified = DateTime.now()
      ..pendingSync = pendingSync;
  }
}
