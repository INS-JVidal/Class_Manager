import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mongo_dart/mongo_dart.dart';

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
  /// Stream that emits current status immediately, then updates.
  Stream<CacheStatus> get statusStream async* {
    yield _currentStatus;
    yield* _statusController.stream;
  }
  CacheStatus get currentStatus => _currentStatus;

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

    switch (op.operationType as String) {
      case 'insert':
        await collection.insertOne(payload);
        break;
      case 'update':
        await collection.replaceOne(
          where.eq('_id', op.entityId),
          payload,
          upsert: true,
        );
        break;
      case 'delete':
        await collection.deleteOne(where.eq('_id', op.entityId));
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

  void dispose() {
    _connectivityTimer?.cancel();
    _statusController.close();
  }
}
