import 'package:isar/isar.dart';

import '../cache/schemas/sync_operation.dart';
import '../cache/sync_queue.dart';
import '../datasources/local_datasource.dart';

/// Base class for caching repositories with local-first persistence.
///
/// This abstract class provides common CRUD operations that handle:
/// - Local Isar caching
/// - Sync queue management for offline-first architecture
/// - Entity-to-cache conversion
///
/// Subclasses must implement:
/// - [collection]: The Isar collection for this entity type
/// - [entityType]: String identifier for sync queue operations
/// - [toCache]: Convert domain entity to cache model
/// - [toEntity]: Convert cache model to domain entity
/// - [toJson]: Serialize entity for sync payload
/// - [getId]: Extract ID from domain entity
///
/// Example:
/// ```dart
/// class CachingGroupRepository extends BaseCachingRepository<Group, GroupCache> {
///   CachingGroupRepository(super.local, super.queue);
///
///   @override
///   String get entityType => 'group';
///
///   @override
///   IsarCollection<GroupCache> get collection => local.db.groupCaches;
///
///   @override
///   GroupCache toCache(Group entity, {bool pendingSync = true}) => ...;
///
///   @override
///   Group toEntity(GroupCache cache) => ...;
///
///   @override
///   Map<String, dynamic> toJson(Group entity) => entity.toJson();
///
///   @override
///   String getId(Group entity) => entity.id;
/// }
/// ```
abstract class BaseCachingRepository<TEntity, TCache> {
  BaseCachingRepository(this.local, this.queue);

  /// The local Isar datasource.
  final LocalDatasource local;

  /// The sync queue for pending operations.
  final SyncQueue queue;

  /// The Isar collection for this entity type.
  IsarCollection<TCache> get collection;

  /// String identifier for this entity type (used in sync queue).
  String get entityType;

  /// Convert a domain entity to its cache representation.
  TCache toCache(TEntity entity, {bool pendingSync = true});

  /// Convert a cache model to its domain entity representation.
  TEntity toEntity(TCache cache);

  /// Serialize the entity to JSON for sync payload.
  Map<String, dynamic> toJson(TEntity entity);

  /// Extract the string ID from a domain entity.
  String getId(TEntity entity);

  /// Find a cache entry by its string ID.
  ///
  /// Subclasses may override this for custom ID filtering.
  /// Default implementation uses filter().idEqualTo().
  Future<TCache?> findCacheById(String id);

  /// Get the Isar ID from a cache model.
  ///
  /// This is needed for updates to preserve the Isar auto-increment ID.
  Id getIsarId(TCache cache);

  /// Set the Isar ID on a cache model.
  void setIsarId(TCache cache, Id isarId);

  /// Retrieve all entities from the local cache.
  Future<List<TEntity>> findAll() async {
    final cached = await collection.where().findAll();
    return cached.map(toEntity).toList();
  }

  /// Find an entity by its string ID.
  Future<TEntity?> findById(String id) async {
    final cached = await findCacheById(id);
    return cached != null ? toEntity(cached) : null;
  }

  /// Insert a new entity into the local cache and queue for sync.
  Future<TEntity> insert(TEntity entity) async {
    await local.db.writeTxn(() async {
      await collection.put(toCache(entity));
    });

    await queue.enqueue(
      entityType: entityType,
      entityId: getId(entity),
      operation: SyncOperationType.insert,
      payload: toJson(entity),
    );

    return entity;
  }

  /// Update an existing entity in the local cache and queue for sync.
  Future<TEntity> update(TEntity entity) async {
    final existing = await findCacheById(getId(entity));
    final cache = toCache(entity);

    if (existing != null) {
      setIsarId(cache, getIsarId(existing));
    }

    await local.db.writeTxn(() async {
      await collection.put(cache);
    });

    await queue.enqueue(
      entityType: entityType,
      entityId: getId(entity),
      operation: SyncOperationType.update,
      payload: toJson(entity),
    );

    return entity;
  }

  /// Delete an entity from the local cache and queue for sync.
  Future<void> delete(String id) async {
    final existing = await findCacheById(id);

    if (existing != null) {
      await local.db.writeTxn(() async {
        await collection.delete(getIsarId(existing));
      });
    }

    await queue.enqueue(
      entityType: entityType,
      entityId: id,
      operation: SyncOperationType.delete,
      payload: {'_id': id},
    );
  }

  /// Replace all local cache entries with remote data.
  ///
  /// This is used during sync to update local cache with server data.
  Future<void> syncFromRemote(List<TEntity> entities) async {
    await local.db.writeTxn(() async {
      await collection.clear();
      for (final entity in entities) {
        await collection.put(toCache(entity, pendingSync: false));
      }
    });
  }
}
