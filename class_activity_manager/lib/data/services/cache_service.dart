import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mongo_dart/mongo_dart.dart';

import '../cache/schemas/schemas.dart';
import '../cache/sync_conflict.dart';
import '../cache/sync_queue.dart';
import '../datasources/local_datasource.dart';
import '../datasources/mongodb_datasource.dart';

/// Connectivity and sync status.
enum CacheStatus { offline, online, syncing }

/// Service that coordinates local cache, remote MongoDB, and sync queue.
class CacheService {
  CacheService(this._local, this._remote, this._queue);

  final LocalDatasource _local;
  final MongoDbDatasource _remote;
  final SyncQueue _queue;

  Timer? _connectivityTimer;
  bool _isSyncing = false;
  CacheStatus _currentStatus = CacheStatus.offline;

  final _statusController = StreamController<CacheStatus>.broadcast();
  final _conflictController = StreamController<SyncConflict>.broadcast();

  /// Stream that emits current status immediately, then updates.
  Stream<CacheStatus> get statusStream async* {
    yield _currentStatus;
    yield* _statusController.stream;
  }

  CacheStatus get currentStatus => _currentStatus;

  /// Stream of sync conflicts for UI notification.
  Stream<SyncConflict> get conflictStream => _conflictController.stream;

  bool get isRemoteConnected => _remote.isConnected;
  LocalDatasource get local => _local;
  MongoDbDatasource get remote => _remote;
  SyncQueue get queue => _queue;

  Future<void> initialize() async {
    // Local datasource should be initialized before this
    if (!_local.isInitialized) {
      await _local.initialize();
    }

    // Check initial remote connection
    if (_remote.isConnected) {
      _updateStatus(CacheStatus.online);
    } else {
      _updateStatus(CacheStatus.offline);
    }

    _startConnectivityMonitor();
  }

  void _updateStatus(CacheStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void _startConnectivityMonitor() {
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAndSync(),
    );
  }

  Future<void> _checkAndSync() async {
    if (_isSyncing) return;

    if (!_remote.isConnected) {
      try {
        await _remote.connect();
        _updateStatus(CacheStatus.online);
        stderr.writeln('Reconnected to MongoDB');
      } catch (e) {
        _updateStatus(CacheStatus.offline);
        return;
      }
    }

    await _processSyncQueue();
  }

  Future<void> _processSyncQueue() async {
    if (_isSyncing) return;

    final pending = await _queue.getPending();
    if (pending.isEmpty) return;

    _isSyncing = true;
    try {
      for (final op in pending) {
        try {
          await _syncOperation(op);
          await _queue.remove(op.id);
        } on ConflictException catch (e) {
          // Conflict detected - remove from queue and notify listeners
          await _queue.remove(op.id);

          // FIX: Update local cache version to match server version
          // This prevents repeated conflicts on subsequent edits
          if (e.type == SyncConflictType.versionMismatch &&
              e.serverDocument != null) {
            final serverVersion = e.serverDocument!['version'] as int? ?? 1;
            await _updateLocalCacheVersion(
              e.entityType,
              e.entityId,
              serverVersion,
            );
          }

          _conflictController.add(
            SyncConflict(
              entityType: e.entityType,
              entityId: e.entityId,
              type: e.type,
              serverDocument: e.serverDocument,
            ),
          );
          stderr.writeln(
            'Sync conflict: ${e.type.name} for ${e.entityType}/${e.entityId}',
          );
        } catch (e) {
          await _queue.markFailed(op.id, e.toString());
          if (op.retryCount >= 3) {
            stderr.writeln(
              'Sync operation failed permanently: ${op.entityType}/${op.entityId}',
            );
          }
        }
      }
      _updateStatus(CacheStatus.online);
    } finally {
      _updateStatus(CacheStatus.online);
      _isSyncing = false;
    }
  }

  Future<void> _syncOperation(dynamic op) async {
    // Validate required fields before casting
    final payloadRaw = op.payload;
    final entityTypeRaw = op.entityType;
    final entityIdRaw = op.entityId;
    final operationTypeRaw = op.operationType;

    if (payloadRaw is! String ||
        entityTypeRaw is! String ||
        entityIdRaw is! String ||
        operationTypeRaw is! String) {
      throw FormatException(
        'Invalid sync operation format: missing or invalid fields',
      );
    }

    final Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(payloadRaw);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Payload is not a valid JSON object');
      }
      payload = decoded;
    } on FormatException {
      rethrow;
    }

    final entityType = entityTypeRaw;
    final entityId = entityIdRaw;
    final collection = _remote.collection(_collectionName(entityType));

    switch (operationTypeRaw) {
      case 'insert':
        // Insert: ensure version is set to 1
        payload['version'] = payload['version'] ?? 1;
        _updateStatus(CacheStatus.syncing);
        try {
          await collection.insertOne(payload);
        } finally {
          _updateStatus(CacheStatus.online);
        }
        break;

      case 'update':
        // Read current version from local cache (not from payload which may be stale)
        final localVersion =
            await _getLocalCacheVersion(entityType, entityId) ??
            payload['version'] as int? ??
            1;

        int newVersion;
        _updateStatus(CacheStatus.syncing);
        try {
          // Fetch current server document
          final serverDoc = await collection.findOne(where.eq('_id', entityId));

          if (serverDoc == null) {
            // Document was deleted on server - conflict
            throw ConflictException(
              type: SyncConflictType.deleted,
              entityType: entityType,
              entityId: entityId,
            );
          }

          final serverVersion = serverDoc['version'] as int? ?? 1;

          if (serverVersion != localVersion) {
            // Version mismatch - conflict
            throw ConflictException(
              type: SyncConflictType.versionMismatch,
              entityType: entityType,
              entityId: entityId,
              serverDocument: serverDoc,
            );
          }

          // Versions match - safe to update with incremented version
          newVersion = localVersion + 1;
          payload['version'] = newVersion;
          await collection.replaceOne(where.eq('_id', entityId), payload);
        } finally {
          _updateStatus(CacheStatus.online);
        }

        // Update local cache version to match synced version (local only)
        await _updateLocalCacheVersion(entityType, entityId, newVersion);
        break;

      case 'delete':
        _updateStatus(CacheStatus.syncing);
        try {
          await collection.deleteOne(where.eq('_id', entityId));
        } finally {
          _updateStatus(CacheStatus.online);
        }
        break;
    }
  }

  String _collectionName(String entityType) {
    return switch (entityType) {
      'modul' => 'moduls',
      'group' => 'groups',
      'dailyNote' => 'daily_notes',
      'academicYear' => 'academic_years',
      'recurringHoliday' => 'recurring_holidays',
      'userPreferences' => 'user_preferences',
      _ => throw ArgumentError('Unknown entity type: $entityType'),
    };
  }

  Future<void> forceSync() async {
    if (!_remote.isConnected) {
      try {
        await _remote.connect();
        _updateStatus(CacheStatus.online);
      } catch (e) {
        throw StateError('Cannot sync: MongoDB not available');
      }
    }
    await _processSyncQueue();
  }

  Future<void> triggerSync() async {
    if (_remote.isConnected) {
      await _processSyncQueue();
    }
  }

  /// Removes a conflicted operation from the queue by entity ID.
  Future<void> removeConflictedOperation(String entityId) async {
    final pending = await _queue.getPending();
    for (final op in pending) {
      if (op.entityId == entityId) {
        await _queue.remove(op.id);
      }
    }
  }

  /// Reads the current version from local Isar cache.
  ///
  /// This ensures we use the accurate version even if in-memory state is stale.
  Future<int?> _getLocalCacheVersion(String entityType, String entityId) async {
    switch (entityType) {
      case 'modul':
        final cache = await _local.db.modulCaches.getById(entityId);
        return cache?.version;
      case 'group':
        final cache = await _local.db.groupCaches.getById(entityId);
        return cache?.version;
      case 'dailyNote':
        final cache = await _local.db.dailyNoteCaches.getById(entityId);
        return cache?.version;
      case 'academicYear':
        final cache = await _local.db.academicYearCaches.getById(entityId);
        return cache?.version;
      case 'recurringHoliday':
        final cache = await _local.db.recurringHolidayCaches.getById(entityId);
        return cache?.version;
      case 'userPreferences':
        final cache = await _local.db.userPreferencesCaches.getById(entityId);
        return cache?.version;
      default:
        return null;
    }
  }

  /// Updates the version in local Isar cache after successful sync.
  ///
  /// This prevents version mismatch on subsequent edits by keeping
  /// local cache version in sync with MongoDB.
  Future<void> _updateLocalCacheVersion(
    String entityType,
    String entityId,
    int newVersion,
  ) async {
    await _local.db.writeTxn(() async {
      switch (entityType) {
        case 'modul':
          final cache = await _local.db.modulCaches.getById(entityId);
          if (cache != null) {
            cache.version = newVersion;
            await _local.db.modulCaches.put(cache);
          }
          break;
        case 'group':
          final cache = await _local.db.groupCaches.getById(entityId);
          if (cache != null) {
            cache.version = newVersion;
            await _local.db.groupCaches.put(cache);
          }
          break;
        case 'dailyNote':
          final cache = await _local.db.dailyNoteCaches.getById(entityId);
          if (cache != null) {
            cache.version = newVersion;
            await _local.db.dailyNoteCaches.put(cache);
          }
          break;
        case 'academicYear':
          final cache = await _local.db.academicYearCaches.getById(entityId);
          if (cache != null) {
            cache.version = newVersion;
            await _local.db.academicYearCaches.put(cache);
          }
          break;
        case 'recurringHoliday':
          final cache = await _local.db.recurringHolidayCaches.getById(
            entityId,
          );
          if (cache != null) {
            cache.version = newVersion;
            await _local.db.recurringHolidayCaches.put(cache);
          }
          break;
        case 'userPreferences':
          final cache = await _local.db.userPreferencesCaches.getById(entityId);
          if (cache != null) {
            cache.version = newVersion;
            await _local.db.userPreferencesCaches.put(cache);
          }
          break;
      }
    });
  }

  void dispose() {
    _connectivityTimer?.cancel();
    _statusController.close();
    _conflictController.close();
  }
}
