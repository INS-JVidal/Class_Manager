import 'package:isar/isar.dart';

import '../../models/user_preferences.dart';
import '../cache/schemas/user_preferences_cache.dart';
import '../cache/schemas/sync_operation.dart';
import '../cache/sync_queue.dart';
import '../datasources/local_datasource.dart';

/// Caching repository for UserPreferences with local-first persistence.
///
/// Does not extend [BaseCachingRepository]: single-document semantics
/// (one active preferences document, findActive vs findAll) and custom
/// sync behaviour. Other entity repos extend BaseCachingRepository.
///
/// Note: There should only be one active preferences document.
class CachingUserPreferencesRepository {
  CachingUserPreferencesRepository(this._local, this._queue);

  final LocalDatasource _local;
  final SyncQueue _queue;

  IsarCollection<UserPreferencesCache> get _collection =>
      _local.db.userPreferencesCaches;

  /// Find the active user preferences (should be only one).
  Future<UserPreferences?> findActive() async {
    final cached = await _collection.where().findFirst();
    return cached != null ? _toPreferences(cached) : null;
  }

  Future<UserPreferences?> findById(String id) async {
    final cached = await _collection.filter().idEqualTo(id).findFirst();
    return cached != null ? _toPreferences(cached) : null;
  }

  Future<UserPreferences> insert(UserPreferences prefs) async {
    await _local.db.writeTxn(() async {
      await _collection.put(_toCache(prefs));
    });

    await _queue.enqueue(
      entityType: 'userPreferences',
      entityId: prefs.id,
      operation: SyncOperationType.insert,
      payload: prefs.toJson(),
    );

    return prefs;
  }

  Future<UserPreferences> update(UserPreferences prefs) async {
    final existing = await _collection.filter().idEqualTo(prefs.id).findFirst();
    final cache = _toCache(prefs);
    if (existing != null) {
      cache.isarId = existing.isarId;
      // Preserve the version from the existing cache to avoid overwriting
      // a version that was updated during conflict resolution
      cache.version = existing.version;
    }

    await _local.db.writeTxn(() async {
      await _collection.put(cache);
    });

    await _queue.enqueue(
      entityType: 'userPreferences',
      entityId: prefs.id,
      operation: SyncOperationType.update,
      payload: prefs.toJson(),
    );

    return prefs;
  }

  /// Save preferences - insert if new, update if exists.
  Future<UserPreferences> save(UserPreferences prefs) async {
    final existing = await findById(prefs.id);
    if (existing != null) {
      return update(prefs);
    } else {
      return insert(prefs);
    }
  }

  Future<void> syncFromRemote(UserPreferences? prefs) async {
    await _local.db.writeTxn(() async {
      await _collection.clear();
      if (prefs != null) {
        await _collection.put(_toCache(prefs, pendingSync: false));
      }
    });
  }

  UserPreferences _toPreferences(UserPreferencesCache cache) {
    return UserPreferences(
      id: cache.id,
      languageCode: cache.languageCode,
      version: cache.version,
    );
  }

  UserPreferencesCache _toCache(
    UserPreferences prefs, {
    bool pendingSync = true,
  }) {
    return UserPreferencesCache()
      ..id = prefs.id
      ..languageCode = prefs.languageCode
      ..version = prefs.version
      ..lastModified = DateTime.now()
      ..pendingSync = pendingSync;
  }
}
