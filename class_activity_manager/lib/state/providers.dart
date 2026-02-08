import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/cache/sync_conflict.dart';
import '../data/cache/sync_queue.dart';
import '../data/datasources/local_datasource.dart';
import '../data/services/cache_service.dart';
import '../data/services/database_service.dart';
import '../router/app_router.dart';

/// Provider for the database service.
/// Returns null if database is not connected.
final databaseServiceProvider = Provider<DatabaseService?>((ref) {
  // Returns null by default - must be overridden in main.dart when DB is connected
  return null;
});

/// Provider for the local Isar datasource (always available).
final localDatasourceProvider = Provider<LocalDatasource>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

/// Provider for the sync queue.
final syncQueueProvider = Provider<SyncQueue>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

/// Provider for the cache service.
final cacheServiceProvider = Provider<CacheService>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

/// Stream provider for cache status (online/offline/syncing).
final cacheStatusProvider = StreamProvider<CacheStatus>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  return cacheService.statusStream;
});

/// Provider for pending sync operation count.
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final queue = ref.watch(syncQueueProvider);
  return queue.pendingCount;
});

/// Stream provider for sync conflicts.
final conflictStreamProvider = StreamProvider<SyncConflict>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  return cacheService.conflictStream;
});

/// Provider for app locale (language).
/// Default is Catalan ('ca'). Can be changed via settings.
final localeProvider = StateProvider<Locale>((ref) => const Locale('ca'));

/// Provider for the GoRouter instance (created once, reused across rebuilds).
final routerProvider = Provider<GoRouter>((ref) => createAppRouter());
