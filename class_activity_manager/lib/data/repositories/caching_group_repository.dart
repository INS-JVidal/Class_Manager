import 'package:isar/isar.dart';

import '../../models/group.dart';
import '../cache/schemas/group_cache.dart';
import 'base_caching_repository.dart';

/// Caching repository for Group with local-first persistence.
///
/// Extends [BaseCachingRepository] to inherit common CRUD operations
/// with automatic sync queue management.
class CachingGroupRepository extends BaseCachingRepository<Group, GroupCache> {
  CachingGroupRepository(super.local, super.queue);

  @override
  String get entityType => 'group';

  @override
  IsarCollection<GroupCache> get collection => local.db.groupCaches;

  @override
  Future<GroupCache?> findCacheById(String id) async {
    return collection.filter().idEqualTo(id).findFirst();
  }

  @override
  Id getIsarId(GroupCache cache) => cache.isarId;

  @override
  void setIsarId(GroupCache cache, Id isarId) => cache.isarId = isarId;

  @override
  void preserveVersion(GroupCache cache, GroupCache existing) {
    cache.version = existing.version;
  }

  @override
  Map<String, dynamic> toJson(Group entity) => entity.toJson();

  @override
  String getId(Group entity) => entity.id;

  @override
  Group toEntity(GroupCache cache) {
    return Group(
      id: cache.id,
      name: cache.name,
      notes: cache.notes,
      academicYearId: cache.academicYearId,
      moduleIds: cache.moduleIds,
      color: cache.color,
      version: cache.version,
    );
  }

  @override
  GroupCache toCache(Group group, {bool pendingSync = true}) {
    return GroupCache()
      ..id = group.id
      ..name = group.name
      ..notes = group.notes
      ..academicYearId = group.academicYearId
      ..moduleIds = group.moduleIds
      ..color = group.color
      ..version = group.version
      ..lastModified = DateTime.now()
      ..pendingSync = pendingSync;
  }

  // --- Entity-specific queries ---

  Future<List<Group>> findByAcademicYear(String academicYearId) async {
    final cached = await collection
        .filter()
        .academicYearIdEqualTo(academicYearId)
        .findAll();
    return cached.map(toEntity).toList();
  }
}
