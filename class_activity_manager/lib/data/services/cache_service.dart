import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mongo_dart/mongo_dart.dart';

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
    _updateStatus(CacheStatus.syncing);

    try {
      for (final op in pending) {
        try {
          await _syncOperation(op);
          await _queue.remove(op.id);
        } on ConflictException catch (e) {
          // Conflict detected - remove from queue and notify listeners
          await _queue.remove(op.id);
          _conflictController.add(SyncConflict(
            entityType: e.entityType,
            entityId: e.entityId,
            type: e.type,
            serverDocument: e.serverDocument,
          ));
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
      _isSyncing = false;
    }
  }

  Future<void> _syncOperation(dynamic op) async {
    final payload = jsonDecode(op.payload as String) as Map<String, dynamic>;
    final collection = _remote.collection(
      _collectionName(op.entityType as String),
    );
    final entityId = op.entityId as String;
    final entityType = op.entityType as String;

    switch (op.operationType as String) {
      case 'insert':
        // Insert: ensure version is set to 1
        payload['version'] = payload['version'] ?? 1;
        await collection.insertOne(payload);
        break;

      case 'update':
        final localVersion = payload['version'] as int? ?? 1;

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
        payload['version'] = localVersion + 1;
        await collection.replaceOne(
          where.eq('_id', entityId),
          payload,
        );
        break;

      case 'delete':
        await collection.deleteOne(where.eq('_id', entityId));
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

  void dispose() {
    _connectivityTimer?.cancel();
    _statusController.close();
    _conflictController.close();
  }
}
