# PRD: Offline-Cached Database Access - v2

## Overview

Add offline caching capability to the Class Activity Manager Flutter desktop app. When MongoDB is unavailable, the app persists data locally and syncs changes when connectivity is restored.

**Key Constraint:** Direct database access only (no REST API layer). The app connects directly to MongoDB using `mongo_dart`.

---

## Current Architecture (v0.1.1)

```
UI (ConsumerWidget)
    → ref.watch(appStateProvider)
    → AppStateNotifier
    → DatabaseService? (nullable - graceful offline)
    → *Repository (5 repositories)
    → MongoDbDatasource (mongo_dart)
    → MongoDB
```

**Current Behavior:**
- App works without MongoDB (in-memory mode)
- Changes made offline are **lost on restart**
- No local persistence layer

---

## Target Architecture (v0.1.2)

```
UI (ConsumerWidget)
    → ref.watch(appStateProvider)
    → AppStateNotifier
    → CacheService (NEW)
        ├── LocalDatasource (Isar - always available)
        ├── RemoteDatasource (MongoDB - when connected)
        └── SyncQueue (pending operations)
```

**Target Behavior:**
- App always works (local Isar cache)
- Changes persist locally even when MongoDB is down
- Automatic sync when MongoDB becomes available
- Single-user desktop app = simple last-write-wins conflict resolution

---

## Local Storage: Isar

### Why Isar?

| Criteria | Isar | Hive | SQLite | JSON Files |
|----------|------|------|--------|------------|
| NoSQL (matches MongoDB) | ✅ | ✅ | ❌ | ✅ |
| Desktop support | ✅ | ✅ | ✅ | ✅ |
| Typed queries | ✅ | ❌ | ✅ | ❌ |
| Flutter-native | ✅ | ✅ | ❌ | ❌ |
| No FFI setup | ✅ | ✅ | ❌ | ✅ |
| Performance | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐ |

**Decision:** Isar is the best fit - NoSQL matches MongoDB document model, excellent Flutter desktop support, typed queries.

---

## Components to Create

### 1. Isar Schemas

Mirror existing models with Isar annotations. Models already have `toJson()`/`fromJson()`.

```
lib/data/cache/
├── schemas/
│   ├── modul_cache.dart
│   ├── group_cache.dart
│   ├── daily_note_cache.dart
│   ├── academic_year_cache.dart
│   ├── recurring_holiday_cache.dart
│   └── sync_operation.dart
└── schemas.g.dart (generated)
```

**Example Schema:**

```dart
// lib/data/cache/schemas/modul_cache.dart
import 'package:isar/isar.dart';

part 'modul_cache.g.dart';

@collection
class ModulCache {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;  // UUID from app model

  late String code;
  late String name;
  String? description;
  late int totalHours;
  late List<String> objectives;
  String? officialReference;
  late String rasJson;  // Nested RAs stored as JSON string
  late List<String> cicleCodes;

  // Sync metadata
  late DateTime lastModified;
  late bool pendingSync;
}

@collection
class SyncOperation {
  Id id = Isar.autoIncrement;

  @Index()
  late String entityType;  // 'modul', 'group', etc.

  late String entityId;
  late String operationType;  // 'insert', 'update', 'delete'
  late String payload;  // JSON of entity
  late DateTime timestamp;
  late int retryCount;
  String? lastError;
}
```

### 2. Local Datasource

```dart
// lib/data/datasources/local_datasource.dart
class LocalDatasource {
  Isar? _isar;

  bool get isInitialized => _isar != null;

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/class_activity_manager';

    _isar = await Isar.open(
      [
        ModulCacheSchema,
        GroupCacheSchema,
        DailyNoteCacheSchema,
        AcademicYearCacheSchema,
        RecurringHolidayCacheSchema,
        SyncOperationSchema,
      ],
      directory: dbPath,
    );
  }

  Isar get db => _isar!;

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
```

### 3. Sync Queue

```dart
// lib/data/cache/sync_queue.dart
enum SyncOperationType { insert, update, delete }

class SyncQueue {
  final LocalDatasource _local;

  SyncQueue(this._local);

  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required SyncOperationType operation,
    required Map<String, dynamic> payload,
  }) async {
    final op = SyncOperation()
      ..entityType = entityType
      ..entityId = entityId
      ..operationType = operation.name
      ..payload = jsonEncode(payload)
      ..timestamp = DateTime.now()
      ..retryCount = 0;

    await _local.db.writeTxn(() async {
      await _local.db.syncOperations.put(op);
    });
  }

  Future<List<SyncOperation>> getPending() async {
    return _local.db.syncOperations
        .where()
        .sortByTimestamp()
        .findAll();
  }

  Future<void> remove(Id id) async {
    await _local.db.writeTxn(() async {
      await _local.db.syncOperations.delete(id);
    });
  }

  Future<void> markFailed(Id id, String error) async {
    final op = await _local.db.syncOperations.get(id);
    if (op != null) {
      op.retryCount++;
      op.lastError = error;
      await _local.db.writeTxn(() async {
        await _local.db.syncOperations.put(op);
      });
    }
  }

  Future<int> get pendingCount async {
    return _local.db.syncOperations.count();
  }
}
```

### 4. Cache Service

Coordinates local cache, remote MongoDB, and sync queue.

```dart
// lib/data/services/cache_service.dart
class CacheService {
  final LocalDatasource _local;
  final MongoDbDatasource _remote;
  final SyncQueue _queue;

  Timer? _connectivityTimer;
  bool _isSyncing = false;

  final _statusController = StreamController<CacheStatus>.broadcast();
  Stream<CacheStatus> get statusStream => _statusController.stream;

  CacheService(this._local, this._remote, this._queue);

  bool get isRemoteConnected => _remote.isConnected;

  Future<void> initialize() async {
    await _local.initialize();
    _startConnectivityMonitor();
  }

  void _startConnectivityMonitor() {
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAndSync(),
    );
  }

  Future<void> _checkAndSync() async {
    if (_isSyncing) return;

    // Try to connect if not connected
    if (!_remote.isConnected) {
      try {
        await _remote.connect();
        _statusController.add(CacheStatus.online);
      } catch (e) {
        _statusController.add(CacheStatus.offline);
        return;
      }
    }

    // Process pending sync operations
    await _processSyncQueue();
  }

  Future<void> _processSyncQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _statusController.add(CacheStatus.syncing);

    try {
      final pending = await _queue.getPending();
      for (final op in pending) {
        try {
          await _syncOperation(op);
          await _queue.remove(op.id);
        } catch (e) {
          await _queue.markFailed(op.id, e.toString());
          if (op.retryCount >= 3) {
            // Log permanent failure, but continue with others
          }
        }
      }
      _statusController.add(CacheStatus.online);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncOperation(SyncOperation op) async {
    final payload = jsonDecode(op.payload) as Map<String, dynamic>;
    final collection = _remote.collection(_collectionName(op.entityType));

    switch (op.operationType) {
      case 'insert':
        await collection.insertOne(payload);
        break;
      case 'update':
        await collection.replaceOne(
          where.eq('_id', op.entityId),
          payload,
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

  /// Initial load: pull from remote if available, otherwise use local cache
  Future<void> initialLoad(AppStateNotifier notifier) async {
    if (_remote.isConnected) {
      await _pullFromRemote(notifier);
    } else {
      await _loadFromLocalCache(notifier);
    }
  }

  Future<void> _pullFromRemote(AppStateNotifier notifier) async {
    // Fetch all data from MongoDB
    final moduls = await _remote.collection('moduls').find().toList();
    final groups = await _remote.collection('groups').find().toList();
    final dailyNotes = await _remote.collection('daily_notes').find().toList();
    final academicYears = await _remote.collection('academic_years').find().toList();
    final holidays = await _remote.collection('recurring_holidays').find().toList();

    // Update local cache
    await _updateLocalCache(moduls, groups, dailyNotes, academicYears, holidays);

    // Update app state
    notifier.loadFromData(
      moduls: moduls.map((m) => Modul.fromJson(m)).toList(),
      groups: groups.map((g) => Group.fromJson(g)).toList(),
      dailyNotes: dailyNotes.map((n) => DailyNote.fromJson(n)).toList(),
      currentYear: academicYears
          .map((y) => AcademicYear.fromJson(y))
          .where((y) => y.isActive)
          .firstOrNull,
      recurringHolidays: holidays.map((h) => RecurringHoliday.fromJson(h)).toList(),
    );
  }

  Future<void> _loadFromLocalCache(AppStateNotifier notifier) async {
    // Load from Isar and convert to app models
    // ... implementation
  }

  Future<void> forcSync() async {
    if (!_remote.isConnected) {
      try {
        await _remote.connect();
      } catch (e) {
        throw StateError('Cannot sync: MongoDB not available');
      }
    }
    await _processSyncQueue();
  }

  void dispose() {
    _connectivityTimer?.cancel();
    _statusController.close();
  }
}

enum CacheStatus { offline, online, syncing }
```

### 5. Caching Repository Pattern

Wrap existing repositories with caching logic.

```dart
// lib/data/repositories/caching_modul_repository.dart
class CachingModulRepository {
  final LocalDatasource _local;
  final MongoDbDatasource? _remote;
  final SyncQueue _queue;

  CachingModulRepository(this._local, this._remote, this._queue);

  Future<List<Modul>> findAll() async {
    // Always read from local cache (fast, offline-capable)
    final cached = await _local.db.modulCaches.where().findAll();
    return cached.map(_toModul).toList();
  }

  Future<Modul> insert(Modul modul) async {
    // Write to local cache immediately
    await _local.db.writeTxn(() async {
      await _local.db.modulCaches.put(_toCache(modul));
    });

    // Queue for remote sync
    await _queue.enqueue(
      entityType: 'modul',
      entityId: modul.id,
      operation: SyncOperationType.insert,
      payload: modul.toJson(),
    );

    return modul;
  }

  Future<Modul> update(Modul modul) async {
    await _local.db.writeTxn(() async {
      await _local.db.modulCaches.put(_toCache(modul));
    });

    await _queue.enqueue(
      entityType: 'modul',
      entityId: modul.id,
      operation: SyncOperationType.update,
      payload: modul.toJson(),
    );

    return modul;
  }

  Future<void> delete(String id) async {
    final existing = await _local.db.modulCaches
        .filter()
        .idEqualTo(id)
        .findFirst();

    if (existing != null) {
      await _local.db.writeTxn(() async {
        await _local.db.modulCaches.delete(existing.isarId);
      });
    }

    await _queue.enqueue(
      entityType: 'modul',
      entityId: id,
      operation: SyncOperationType.delete,
      payload: {'_id': id},
    );
  }

  Modul _toModul(ModulCache cache) {
    return Modul(
      id: cache.id,
      code: cache.code,
      name: cache.name,
      description: cache.description,
      totalHours: cache.totalHours,
      objectives: cache.objectives,
      officialReference: cache.officialReference,
      ras: (jsonDecode(cache.rasJson) as List)
          .map((r) => RA.fromJson(r))
          .toList(),
      cicleCodes: cache.cicleCodes,
    );
  }

  ModulCache _toCache(Modul modul) {
    return ModulCache()
      ..id = modul.id
      ..code = modul.code
      ..name = modul.name
      ..description = modul.description
      ..totalHours = modul.totalHours
      ..objectives = modul.objectives
      ..officialReference = modul.officialReference
      ..rasJson = jsonEncode(modul.ras.map((r) => r.toJson()).toList())
      ..cicleCodes = modul.cicleCodes
      ..lastModified = DateTime.now()
      ..pendingSync = true;
  }
}
```

---

## Provider Changes

```dart
// lib/state/providers.dart

// Local datasource (always available)
final localDatasourceProvider = Provider<LocalDatasource>((ref) {
  throw UnimplementedError('Override in main');
});

// Sync queue
final syncQueueProvider = Provider<SyncQueue>((ref) {
  final local = ref.watch(localDatasourceProvider);
  return SyncQueue(local);
});

// Cache service
final cacheServiceProvider = Provider<CacheService>((ref) {
  final local = ref.watch(localDatasourceProvider);
  final remote = ref.watch(databaseServiceProvider);
  final queue = ref.watch(syncQueueProvider);
  return CacheService(local, remote?.datasource, queue);
});

// Connectivity status for UI
final cacheStatusProvider = StreamProvider<CacheStatus>((ref) {
  return ref.watch(cacheServiceProvider).statusStream;
});

// Pending sync count for UI indicator
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final queue = ref.watch(syncQueueProvider);
  return queue.pendingCount;
});
```

---

## main.dart Changes

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... single instance guard ...

  await dotenv.load(fileName: 'lib/.env');

  // 1. Initialize local storage FIRST (always available)
  final localDatasource = LocalDatasource();
  await localDatasource.initialize();

  // 2. Try MongoDB connection (optional)
  final mongoDatasource = MongoDbDatasource();
  DatabaseService? databaseService;
  try {
    await mongoDatasource.connect();
    databaseService = DatabaseService(mongoDatasource);
    stderr.writeln('Connected to MongoDB');
  } catch (e) {
    stderr.writeln('Starting in offline mode: $e');
  }

  // 3. Create sync infrastructure
  final syncQueue = SyncQueue(localDatasource);
  final cacheService = CacheService(
    localDatasource,
    mongoDatasource,
    syncQueue,
  );
  await cacheService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        localDatasourceProvider.overrideWithValue(localDatasource),
        databaseServiceProvider.overrideWithValue(databaseService),
        syncQueueProvider.overrideWithValue(syncQueue),
        cacheServiceProvider.overrideWithValue(cacheService),
      ],
      child: const _AppWithDatabaseInit(),
    ),
  );
}
```

---

## UI: Sync Status Indicator

Add to `AppShell` to show connection and sync status.

```dart
// lib/presentation/widgets/sync_status_indicator.dart
class SyncStatusIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(cacheStatusProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return status.when(
      data: (s) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (s) {
              CacheStatus.online => Icons.cloud_done,
              CacheStatus.offline => Icons.cloud_off,
              CacheStatus.syncing => Icons.sync,
            },
            color: switch (s) {
              CacheStatus.online => Colors.green,
              CacheStatus.offline => Colors.orange,
              CacheStatus.syncing => Colors.blue,
            },
            size: 20,
          ),
          const SizedBox(width: 4),
          if (s == CacheStatus.offline)
            const Text('Offline', style: TextStyle(fontSize: 12)),
          if (s == CacheStatus.syncing)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          pendingCount.when(
            data: (count) => count > 0
                ? Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(Icons.error, size: 20, color: Colors.red),
    );
  }
}
```

---

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  path_provider: ^2.1.2

dev_dependencies:
  isar_generator: ^3.1.0+1
  build_runner: ^2.4.8
```

Run after adding:
```bash
flutter pub get
flutter pub run build_runner build
```

---

## Sync Strategy

### Write Flow (Local-First)

1. User action triggers state update
2. Write to local Isar immediately (instant UI response)
3. Enqueue sync operation
4. If MongoDB connected → process queue immediately
5. If offline → queue waits for reconnection

### Read Flow

1. Always read from local Isar cache (fast, consistent)
2. On app start, if MongoDB connected → pull latest and update cache
3. Periodic background sync (every 30s) when connected

### Conflict Resolution (Single-User)

Since this is a single-user desktop app with single-instance enforcement:
- **Last-write-wins** is sufficient
- Local changes always take precedence (user's latest intent)
- No vector clocks or CRDTs needed

```dart
// Simple: local timestamp > remote = push local
// (Edge case: same entity modified while offline AND on remote - unlikely for single user)
```

---

## Files to Create/Modify

### New Files

| File | Purpose |
|------|---------|
| `lib/data/cache/schemas/modul_cache.dart` | Isar schema for Modul |
| `lib/data/cache/schemas/group_cache.dart` | Isar schema for Group |
| `lib/data/cache/schemas/daily_note_cache.dart` | Isar schema for DailyNote |
| `lib/data/cache/schemas/academic_year_cache.dart` | Isar schema for AcademicYear |
| `lib/data/cache/schemas/recurring_holiday_cache.dart` | Isar schema for RecurringHoliday |
| `lib/data/cache/schemas/sync_operation.dart` | Isar schema for sync queue |
| `lib/data/datasources/local_datasource.dart` | Isar wrapper |
| `lib/data/cache/sync_queue.dart` | Pending operations queue |
| `lib/data/services/cache_service.dart` | Coordination layer |
| `lib/data/repositories/caching_*_repository.dart` | 5 caching repositories |
| `lib/presentation/widgets/sync_status_indicator.dart` | UI status widget |

### Modified Files

| File | Changes |
|------|---------|
| `pubspec.yaml` | Add isar dependencies |
| `lib/state/providers.dart` | Add cache-related providers |
| `lib/state/app_state.dart` | Update to use caching repositories |
| `lib/main.dart` | Initialize local datasource first |
| `lib/presentation/shell/app_shell.dart` | Add sync status indicator |

---

## Implementation Phases

### Phase 1: Isar Setup
1. Add dependencies to pubspec.yaml
2. Create all Isar schema files
3. Run `build_runner` to generate code
4. Create `LocalDatasource`
5. Test: verify Isar opens and closes correctly

### Phase 2: Sync Infrastructure
1. Create `SyncQueue`
2. Create `CacheService` (without full sync logic)
3. Add providers
4. Test: verify queue enqueue/dequeue works

### Phase 3: Caching Repositories
1. Create `CachingModulRepository`
2. Create remaining 4 caching repositories
3. Test: verify local CRUD operations

### Phase 4: Integration
1. Update `main.dart` initialization
2. Modify `AppStateNotifier` to use caching repositories
3. Implement full sync logic in `CacheService`
4. Test: offline changes persist, sync when online

### Phase 5: UI Polish
1. Add `SyncStatusIndicator` to `AppShell`
2. Add manual sync button
3. Handle sync errors gracefully
4. Test: full offline/online transition scenarios

---

## Testing Scenarios

1. **Start with MongoDB running** → data loads from remote, cached locally
2. **Start with MongoDB down** → data loads from local cache
3. **MongoDB goes down while running** → changes saved locally, queued for sync
4. **MongoDB comes back** → queued changes sync automatically
5. **Many changes offline, then reconnect** → all changes sync in order
6. **Kill app while offline, restart with MongoDB** → local changes sync on startup

---

## Notes

- No API layer - direct `mongo_dart` connection maintained
- Simple hosting: just run MongoDB (Docker or native)
- All complexity is in the Flutter app, not a backend
- Single-instance guard prevents concurrent local modifications
- Isar provides fast local queries for UI responsiveness
