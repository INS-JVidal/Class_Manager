# Local-First Database Architecture with MongoDB Atlas Sync

**Version:** 1.0  
**Date:** 2026-02-01  
**Based on:** v0.1.4 Implementation

---

## Table of Contents

1. [Overview](#1-overview)
2. [Design Principles](#2-design-principles)
3. [Static Architecture](#3-static-architecture)
4. [Component Descriptions](#4-component-descriptions)
5. [Sequence Diagrams](#5-sequence-diagrams)
6. [Conflict Detection and Resolution](#6-conflict-detection-and-resolution)
7. [Data Flow Summary](#7-data-flow-summary)
8. [Implementation Details](#8-implementation-details)

---

## 1. Overview

Class Activity Manager uses a **local-first architecture** that prioritizes offline capability and instant UI responsiveness. All data operations write to a local Isar database first, then synchronize with MongoDB Atlas when connectivity is available.

### Key Characteristics

| Aspect | Implementation |
|--------|----------------|
| **Local Storage** | Isar NoSQL database |
| **Remote Storage** | MongoDB Atlas (cloud) |
| **Sync Strategy** | Write-local-first, async sync to remote |
| **Conflict Resolution** | Optimistic locking with version numbers |
| **Connectivity** | Periodic monitoring (30-second intervals) |

### Benefits

- **Instant UI Response**: No network latency on user actions
- **Offline Capability**: Full functionality without internet
- **Data Durability**: Local persistence survives app restarts
- **Automatic Sync**: Background synchronization when online

---

## 2. Design Principles

### 2.1 Local-First

All read and write operations target the local Isar cache. The remote MongoDB is treated as a secondary store for:
- Data backup and durability
- Multi-device synchronization (future)
- Cloud persistence

### 2.2 Eventual Consistency

The system provides eventual consistency between local and remote stores:
- Local writes are immediately visible
- Remote sync happens asynchronously
- Conflicts are detected and resolved automatically

### 2.3 Single-User Simplification

As a single-user desktop application with single-instance enforcement:
- No concurrent user conflicts
- Last-write-wins is acceptable
- No complex CRDT or vector clock needed

---

## 3. Static Architecture

### 3.1 Layer Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  Dashboard  │  │  Calendar   │  │   Moduls    │  │ DailyNotes  │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                │                │                │            │
│         └────────────────┴────────────────┴────────────────┘            │
│                                   │                                     │
│                          ┌────────┴────────┐                            │
│                          │  ref.watch()    │                            │
│                          │  ref.read()     │                            │
│                          └────────┬────────┘                            │
└──────────────────────────────────┼──────────────────────────────────────┘
                                   │
┌──────────────────────────────────┼──────────────────────────────────────┐
│                         STATE LAYER (Riverpod)                          │
│                          ┌────────┴────────┐                            │
│                          │ AppStateNotifier │                           │
│                          │                  │                           │
│                          │ • loadFromDb()   │                           │
│                          │ • addGroup()     │                           │
│                          │ • setDailyNote() │                           │
│                          └────────┬────────┘                            │
│                                   │                                     │
│        ┌──────────────────────────┼──────────────────────────┐          │
│        │                          │                          │          │
│  ┌─────┴─────┐            ┌───────┴───────┐          ┌───────┴───────┐  │
│  │  Caching  │            │     Sync      │          │     Cache     │  │
│  │   Repos   │            │     Queue     │          │    Service    │  │
│  │           │            │               │          │               │  │
│  │ • insert()│            │ • enqueue()   │          │ • initialize()│  │
│  │ • update()│            │ • getPending()│          │ • triggerSync()│ │
│  │ • delete()│            │ • remove()    │          │ • forceSync() │  │
│  └─────┬─────┘            └───────┬───────┘          └───────┬───────┘  │
└────────┼──────────────────────────┼──────────────────────────┼──────────┘
         │                          │                          │
┌────────┼──────────────────────────┼──────────────────────────┼──────────┐
│        │                     DATA LAYER                      │          │
│        │                          │                          │          │
│  ┌─────┴─────┐            ┌───────┴───────┐          ┌───────┴───────┐  │
│  │   Isar    │            │     Isar      │          │    MongoDB    │  │
│  │  Caches   │            │   SyncOps     │          │     Atlas     │  │
│  │           │            │               │          │               │  │
│  │ • Modul   │            │ SyncOperation │          │ • moduls      │  │
│  │ • Group   │            │  collection   │          │ • groups      │  │
│  │ • Note    │            │               │          │ • daily_notes │  │
│  └───────────┘            └───────────────┘          └───────────────┘  │
│                                                                         │
│       LOCAL (Always Available)              REMOTE (When Connected)     │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Component Diagram

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              CLASS DIAGRAM                                 │
└────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐       ┌─────────────────────────┐
│      CacheService       │       │      LocalDatasource    │
├─────────────────────────┤       ├─────────────────────────┤
│ - _local: LocalDS       │──────▶│ - _isar: Isar?          │
│ - _remote: MongoDS      │       ├─────────────────────────┤
│ - _queue: SyncQueue     │       │ + db: Isar              │
│ - _isSyncing: bool      │       │ + initialize()          │
│ - _currentStatus: enum  │       │ + close()               │
├─────────────────────────┤       └─────────────────────────┘
│ + initialize()          │
│ + triggerSync()         │       ┌─────────────────────────┐
│ + forceSync()           │       │    MongoDbDatasource    │
│ - _processSyncQueue()   │──────▶├─────────────────────────┤
│ - _syncOperation()      │       │ - _db: Db?              │
│ - _checkAndSync()       │       ├─────────────────────────┤
└──────────┬──────────────┘       │ + connect()             │
           │                      │ + collection(name)      │
           │                      │ + isConnected: bool     │
           ▼                      └─────────────────────────┘
┌─────────────────────────┐
│       SyncQueue         │
├─────────────────────────┤
│ - _local: LocalDS       │
├─────────────────────────┤       ┌─────────────────────────┐
│ + enqueue()             │       │ BaseCachingRepository   │
│ + getPending()          │◀──────│        <T, C>           │
│ + remove(id)            │       ├─────────────────────────┤
│ + markFailed(id, error) │       │ # local: LocalDS        │
│ + pendingCount          │       │ # queue: SyncQueue      │
└─────────────────────────┘       ├─────────────────────────┤
                                  │ + findAll(): List<T>    │
                                  │ + findById(id): T?      │
                                  │ + insert(entity): T     │
                                  │ + update(entity): T     │
                                  │ + delete(id): void      │
                                  │ + syncFromRemote(list)  │
                                  │ # preserveVersion()     │
                                  └───────────┬─────────────┘
                                              │
              ┌───────────────────────────────┼───────────────────────────────┐
              │                               │                               │
              ▼                               ▼                               ▼
┌─────────────────────────┐   ┌─────────────────────────┐   ┌─────────────────────────┐
│ CachingModulRepository  │   │CachingDailyNoteRepository│  │ CachingGroupRepository  │
├─────────────────────────┤   ├─────────────────────────┤   ├─────────────────────────┤
│ entityType: "modul"     │   │ entityType: "dailyNote" │   │ entityType: "group"     │
│ collection: modulCaches │   │ collection: noteCaches  │   │ collection: groupCaches │
├─────────────────────────┤   ├─────────────────────────┤   ├─────────────────────────┤
│ + findByCode()          │   │ + findByGroupRaDate()   │   │ + findByAcademicYear()  │
│ + toCache()             │   │ + findByRaId()          │   │ + toCache()             │
│ + toEntity()            │   │ + toCache()             │   │ + toEntity()            │
└─────────────────────────┘   └─────────────────────────┘   └─────────────────────────┘
```

### 3.3 Data Model with Version Field

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        CACHE SCHEMAS (Isar)                                │
└────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐     ┌─────────────────────────┐
│      DailyNoteCache     │     │       ModulCache        │
├─────────────────────────┤     ├─────────────────────────┤
│ isarId: Id (auto)       │     │ isarId: Id (auto)       │
│ id: String (UUID)       │     │ id: String (UUID)       │
│ raId: String            │     │ code: String            │
│ modulId: String         │     │ name: String            │
│ groupId: String         │     │ totalHours: int         │
│ date: DateTime          │     │ rasJson: String         │
│ plannedContent: String? │     │ cicleCodes: List        │
│ actualContent: String?  │     │                         │
│ notes: String?          │     │ ┌─────────────────────┐ │
│ completed: bool         │     │ │ SYNC METADATA       │ │
│                         │     │ ├─────────────────────┤ │
│ ┌─────────────────────┐ │     │ │ version: int = 1    │ │
│ │ SYNC METADATA       │ │     │ │ lastModified: Date  │ │
│ ├─────────────────────┤ │     │ │ pendingSync: bool   │ │
│ │ version: int = 1    │ │     │ └─────────────────────┘ │
│ │ lastModified: Date  │ │     └─────────────────────────┘
│ │ pendingSync: bool   │ │
│ └─────────────────────┘ │     ┌─────────────────────────┐
└─────────────────────────┘     │     SyncOperation       │
                                ├─────────────────────────┤
                                │ id: Id (auto)           │
                                │ entityType: String      │
                                │ entityId: String        │
                                │ operationType: String   │
                                │   (insert/update/delete)│
                                │ payload: String (JSON)  │
                                │ timestamp: DateTime     │
                                │ retryCount: int         │
                                │ lastError: String?      │
                                └─────────────────────────┘
```

---

## 4. Component Descriptions

### 4.1 LocalDatasource

**Location:** `lib/data/datasources/local_datasource.dart`

The wrapper around Isar NoSQL database providing local persistence.

**Responsibilities:**
- Initialize Isar database on app startup
- Provide access to all cache collections
- Manage database lifecycle

**Key Properties:**
- `db`: The Isar database instance
- `isInitialized`: Whether Isar is ready

### 4.2 SyncQueue

**Location:** `lib/data/cache/sync_queue.dart`

Manages pending synchronization operations using an Isar collection.

**Responsibilities:**
- Enqueue new sync operations
- Deduplicate operations (one per entity)
- Track retry counts and errors
- Maintain operation order by timestamp

**Key Methods:**
| Method | Description |
|--------|-------------|
| `enqueue()` | Add operation, replacing any existing for same entity |
| `getPending()` | Get all pending ops sorted by timestamp |
| `remove()` | Delete processed operation |
| `markFailed()` | Increment retry count, store error |

**Deduplication Logic:**
```dart
await _local.db.writeTxn(() async {
  // Remove any existing pending operation for this entity
  final existing = await _local.db.syncOperations
      .filter()
      .entityTypeEqualTo(entityType)
      .and()
      .entityIdEqualTo(entityId)
      .findAll();
  for (final old in existing) {
    await _local.db.syncOperations.delete(old.id);
  }
  // Add the new operation with latest data
  await _local.db.syncOperations.put(op);
});
```

### 4.3 CacheService

**Location:** `lib/data/services/cache_service.dart`

The central coordinator for local cache, remote MongoDB, and sync operations.

**Responsibilities:**
- Monitor connectivity (30-second timer)
- Process sync queue when online
- Detect and handle conflicts
- Emit status updates via stream
- Update version numbers after successful sync

**Status States:**
| Status | Description | UI Indicator |
|--------|-------------|--------------|
| `offline` | No MongoDB connection | Amber LED |
| `online` | Connected, queue empty | Green LED |
| `syncing` | Processing network operations | Amber LED (briefly) |

**Key Methods:**
| Method | Description |
|--------|-------------|
| `initialize()` | Start connectivity monitor |
| `triggerSync()` | Process queue if online |
| `forceSync()` | Connect if needed, then process queue |
| `_syncOperation()` | Execute single sync with conflict detection |

### 4.4 BaseCachingRepository

**Location:** `lib/data/repositories/base_caching_repository.dart`

Abstract base class providing local-first CRUD operations.

**Responsibilities:**
- Write to local Isar immediately
- Enqueue sync operations
- Preserve version numbers during updates
- Convert between domain and cache models

**Required Implementations by Subclasses:**
| Method | Purpose |
|--------|---------|
| `collection` | Isar collection getter |
| `entityType` | String identifier for sync queue |
| `toCache()` | Domain → Cache conversion |
| `toEntity()` | Cache → Domain conversion |
| `toJson()` | Serialize for sync payload |
| `preserveVersion()` | Copy version from existing cache |

### 4.5 Conflict Types

**Location:** `lib/data/cache/sync_conflict.dart`

```dart
enum SyncConflictType {
  none,           // No conflict
  versionMismatch, // Server has newer version
  deleted,        // Entity deleted on server
}
```

---

## 5. Sequence Diagrams

### 5.1 Write Operation (Online)

```
┌────────────────────────────────────────────────────────────────────────────┐
│              SEQUENCE: Write Operation (Online Scenario)                   │
└────────────────────────────────────────────────────────────────────────────┘

User        UI            AppStateNotifier    CachingRepo     SyncQueue    CacheService    MongoDB
 │           │                  │                 │              │              │             │
 │  Edit     │                  │                 │              │              │             │
 │  note     │                  │                 │              │              │             │
 │──────────▶│                  │                 │              │              │             │
 │           │  setDailyNote()  │                 │              │              │             │
 │           │─────────────────▶│                 │              │              │             │
 │           │                  │                 │              │              │             │
 │           │                  │  update(note)   │              │              │             │
 │           │                  │────────────────▶│              │              │             │
 │           │                  │                 │              │              │             │
 │           │                  │                 │  1. Write    │              │             │
 │           │                  │                 │    to Isar   │              │             │
 │           │                  │                 │──────────────│              │             │
 │           │                  │                 │   (local)    │              │             │
 │           │                  │                 │              │              │             │
 │           │                  │                 │  2. enqueue()│              │             │
 │           │                  │                 │─────────────▶│              │             │
 │           │                  │                 │              │              │             │
 │           │                  │                 │◀─────────────│              │             │
 │           │                  │◀────────────────│              │              │             │
 │           │                  │                 │              │              │             │
 │           │                  │  triggerSync()  │              │              │             │
 │           │                  │─────────────────│──────────────│─────────────▶│             │
 │           │                  │  (fire-and-forget)             │              │             │
 │           │                  │                 │              │              │             │
 │           │  State updated   │                 │              │ _processSyncQueue()        │
 │           │◀─────────────────│                 │              │              │             │
 │           │                  │                 │              │ getPending() │             │
 │  UI       │                  │                 │              │◀─────────────│             │
 │  updates  │                  │                 │              │              │             │
 │◀──────────│                  │                 │              │  ops list    │             │
 │           │                  │                 │              │─────────────▶│             │
 │           │                  │                 │              │              │             │
 │           │                  │                 │              │  For each op:│             │
 │           │                  │                 │              │  _syncOperation()          │
 │           │                  │                 │              │              │             │
 │           │                  │                 │              │  status=     │             │
 │           │                  │                 │              │  syncing     │             │
 │           │                  │                 │              │──────────────│             │
 │           │                  │                 │              │              │  findOne()  │
 │           │                  │                 │              │              │────────────▶│
 │           │                  │                 │              │              │             │
 │           │                  │                 │              │              │  serverDoc  │
 │           │                  │                 │              │              │◀────────────│
 │           │                  │                 │              │              │             │
 │           │                  │                 │              │  (version    │             │
 │           │                  │                 │              │   check OK)  │             │
 │           │                  │                 │              │              │ replaceOne()│
 │           │                  │                 │              │              │────────────▶│
 │           │                  │                 │              │              │             │
 │           │                  │                 │              │              │     OK      │
 │           │                  │                 │              │              │◀────────────│
 │           │                  │                 │              │              │             │
 │           │                  │                 │              │  status=     │             │
 │           │                  │                 │              │  online      │             │
 │           │                  │                 │              │──────────────│             │
 │           │                  │                 │              │              │             │
 │           │                  │                 │              │  remove(op)  │             │
 │           │                  │                 │              │◀─────────────│             │
 │           │                  │                 │              │              │             │
 │           │                  │                 │              │  _updateLocalCacheVersion()│
 │           │                  │                 │              │──────────────│             │
 │           │                  │                 │              │   (Isar)     │             │
 │           │                  │                 │              │              │             │
```

### 5.2 Write Operation (Offline)

```
┌────────────────────────────────────────────────────────────────────────────┐
│              SEQUENCE: Write Operation (Offline Scenario)                  │
└────────────────────────────────────────────────────────────────────────────┘

User        UI            AppStateNotifier    CachingRepo     SyncQueue    CacheService
 │           │                  │                 │              │              │
 │  Edit     │                  │                 │              │              │
 │  note     │                  │                 │              │              │
 │──────────▶│                  │                 │              │              │
 │           │  setDailyNote()  │                 │              │              │
 │           │─────────────────▶│                 │              │              │
 │           │                  │                 │              │              │
 │           │                  │  update(note)   │              │              │
 │           │                  │────────────────▶│              │              │
 │           │                  │                 │              │              │
 │           │                  │                 │  1. Write    │              │
 │           │                  │                 │    to Isar   │              │
 │           │                  │                 │──────────────│              │
 │           │                  │                 │   (local)    │              │
 │           │                  │                 │              │              │
 │           │                  │                 │  2. enqueue()│              │
 │           │                  │                 │─────────────▶│              │
 │           │                  │                 │              │  (persists   │
 │           │                  │                 │              │   to Isar)   │
 │           │                  │                 │◀─────────────│              │
 │           │                  │◀────────────────│              │              │
 │           │                  │                 │              │              │
 │           │                  │  triggerSync()  │              │              │
 │           │                  │─────────────────│──────────────│─────────────▶│
 │           │                  │                 │              │              │
 │           │                  │                 │              │  isConnected │
 │           │                  │                 │              │  = false     │
 │           │                  │                 │              │◀─────────────│
 │           │  State updated   │                 │              │   (no-op)    │
 │           │◀─────────────────│                 │              │              │
 │           │                  │                 │              │              │
 │  UI       │                  │                 │              │              │
 │  updates  │                  │                 │              │              │
 │  (instant)│                  │                 │              │              │
 │◀──────────│                  │                 │              │              │
 │           │                  │                 │              │              │
 │           │                  │                 │              │              │
~~~~~ TIME PASSES (30 seconds) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 │           │                  │                 │              │              │
 │           │                  │                 │              │  Timer fires │
 │           │                  │                 │              │  _checkAndSync()
 │           │                  │                 │              │              │
 │           │                  │                 │              │  Try connect │
 │           │                  │                 │              │──────────────│──▶ MongoDB
 │           │                  │                 │              │              │
 │           │                  │                 │              │  Connected!  │
 │           │                  │                 │              │◀─────────────│◀──
 │           │                  │                 │              │              │
 │           │                  │                 │              │ _processSyncQueue()
 │           │                  │                 │              │  (syncs all  │
 │           │                  │                 │              │   pending)   │
 │           │                  │                 │              │──────────────│──▶ MongoDB
 │           │                  │                 │              │              │
```

### 5.3 Application Startup

```
┌────────────────────────────────────────────────────────────────────────────┐
│                    SEQUENCE: Application Startup                           │
└────────────────────────────────────────────────────────────────────────────┘

main()          LocalDS         MongoDS        CacheService    AppStateNotifier
  │                │               │                │                 │
  │  1. Initialize │               │                │                 │
  │     local DB   │               │                │                 │
  │───────────────▶│               │                │                 │
  │                │               │                │                 │
  │  Isar.open()   │               │                │                 │
  │◀───────────────│               │                │                 │
  │                │               │                │                 │
  │  2. Try MongoDB│               │                │                 │
  │     connect    │               │                │                 │
  │────────────────│──────────────▶│                │                 │
  │                │               │                │                 │
  │  (may fail)    │               │                │                 │
  │◀───────────────│───────────────│                │                 │
  │                │               │                │                 │
  │  3. Create     │               │                │                 │
  │     CacheService               │                │                 │
  │───────────────────────────────────────────────▶│                 │
  │                │               │                │                 │
  │  4. Initialize │               │                │                 │
  │     CacheService               │                │                 │
  │───────────────────────────────────────────────▶│                 │
  │                │               │                │                 │
  │                │               │     Start 30s  │                 │
  │                │               │     timer      │                 │
  │                │               │                │◀────────────────│
  │                │               │                │                 │
  │  5. Setup      │               │                │                 │
  │     providers  │               │                │                 │
  │     (overrides)│               │                │                 │
  │────────────────│───────────────│────────────────│────────────────▶│
  │                │               │                │                 │
  │  runApp()      │               │                │                 │
  │                │               │                │                 │

                   ~~~ After First Frame ~~~

UI                                                           AppStateNotifier
 │                                                                  │
 │  loadFromDatabase()                                              │
 │─────────────────────────────────────────────────────────────────▶│
 │                                                                  │
 │                                          ┌───────────────────────┤
 │                                          │ MongoDB connected?    │
 │                                          └───────────┬───────────┘
 │                                                      │
 │                               ┌──────────────────────┴──────────────────────┐
 │                               │                                             │
 │                         [YES: Online]                                 [NO: Offline]
 │                               │                                             │
 │                     _pullFromRemote()                          _loadFromLocalCache()
 │                               │                                             │
 │                     1. Fetch all from MongoDB                  1. Read all from Isar
 │                     2. Update local cache                      2. Update state
 │                     3. Update state                                         │
 │                               │                                             │
 │                               └──────────────────────┬──────────────────────┘
 │                                                      │
 │                                             triggerSync()
 │                                          (process any pending)
 │                                                      │
 │  UI renders with data                                │
 │◀─────────────────────────────────────────────────────│
 │                                                      │
```

### 5.4 Conflict Detection and Resolution

```
┌────────────────────────────────────────────────────────────────────────────┐
│           SEQUENCE: Conflict Detection and Resolution                      │
└────────────────────────────────────────────────────────────────────────────┘

Timeline:
─────────────────────────────────────────────────────────────────────────────▶

    T1                    T2                    T3                    T4
    │                     │                     │                     │
    │  User edits note    │  (Offline)          │  Connection         │  Conflict
    │  Local: v5          │  Server: updated    │  restored           │  resolved
    │  Queue: v5          │  to v6              │                     │
    │                     │                     │                     │


CacheService                 SyncQueue                   MongoDB                Isar
    │                           │                           │                     │
    │                           │                    ┌──────┴──────┐              │
    │                           │                    │ Server has  │              │
    │                           │                    │ version 6   │              │
    │                           │                    │ (updated    │              │
    │                           │                    │  elsewhere) │              │
    │                           │                    └──────┬──────┘              │
    │                           │                           │                     │
    │  _processSyncQueue()      │                           │                     │
    │──────────────────────────▶│                           │                     │
    │                           │                           │                     │
    │  getPending()             │                           │                     │
    │◀──────────────────────────│                           │                     │
    │                           │                           │                     │
    │  ops = [update note v5]   │                           │                     │
    │                           │                           │                     │
    │  _syncOperation()         │                           │                     │
    │                           │                           │                     │
    │  1. Read local version    │                           │                     │
    │     from Isar             │                           │                     │
    │───────────────────────────│───────────────────────────│────────────────────▶│
    │                           │                           │                     │
    │  localVersion = 5         │                           │                     │
    │◀──────────────────────────│───────────────────────────│─────────────────────│
    │                           │                           │                     │
    │  2. Fetch server doc      │                           │                     │
    │──────────────────────────────────────────────────────▶│                     │
    │                           │                           │                     │
    │  serverDoc {version: 6}   │                           │                     │
    │◀──────────────────────────────────────────────────────│                     │
    │                           │                           │                     │
    │  3. Compare versions      │                           │                     │
    │     5 ≠ 6 → CONFLICT!     │                           │                     │
    │                           │                           │                     │
    │  throw ConflictException( │                           │                     │
    │    type: versionMismatch, │                           │                     │
    │    serverDoc: {...}       │                           │                     │
    │  )                        │                           │                     │
    │                           │                           │                     │
    │  catch ConflictException  │                           │                     │
    │                           │                           │                     │
    │  4. Remove from queue     │                           │                     │
    │──────────────────────────▶│                           │                     │
    │                           │  delete(op.id)            │                     │
    │                           │                           │                     │
    │  5. Update local cache    │                           │                     │
    │     version to 6          │                           │                     │
    │───────────────────────────│───────────────────────────│────────────────────▶│
    │                           │                           │      cache.v = 6    │
    │                           │                           │                     │
    │  6. Emit conflict event   │                           │                     │
    │     for UI notification   │                           │                     │
    │──────────────────────────▶│ (conflictStream)          │                     │
    │                           │                           │                     │
    │                           │                           │                     │
    │  *** Next user edit ***   │                           │                     │
    │                           │                           │                     │
    │  User edits again         │                           │                     │
    │  Local reads v6 from Isar │                           │                     │
    │  Server has v6            │                           │                     │
    │  Versions match!          │                           │                     │
    │  → Sync succeeds with v7  │                           │                     │
    │                           │                           │                     │
```

---

## 6. Conflict Detection and Resolution

### 6.1 Optimistic Locking with Versions

Every entity has a `version` field that:
- Starts at 1 for new entities
- Increments on each successful sync
- Is stored in both local Isar cache and MongoDB

### 6.2 Version Check During Sync

```dart
case 'update':
  // Read current version from local cache
  final localVersion = await _getLocalCacheVersion(entityType, entityId)
      ?? payload['version'] as int? ?? 1;

  // Fetch server document
  final serverDoc = await collection.findOne(where.eq('_id', entityId));

  if (serverDoc == null) {
    throw ConflictException(type: SyncConflictType.deleted, ...);
  }

  final serverVersion = serverDoc['version'] as int? ?? 1;

  if (serverVersion != localVersion) {
    throw ConflictException(
      type: SyncConflictType.versionMismatch,
      serverDocument: serverDoc,
      ...
    );
  }

  // Versions match - safe to update
  final newVersion = localVersion + 1;
  payload['version'] = newVersion;
  await collection.replaceOne(where.eq('_id', entityId), payload);
```

### 6.3 Conflict Resolution Strategy

When a version mismatch is detected:

1. **Remove operation from queue** - Prevents repeated conflict attempts
2. **Update local cache version** - Align with server version
3. **Emit conflict notification** - UI can show message to user
4. **Next edit succeeds** - Uses corrected version

```dart
catch (e as ConflictException) {
  await _queue.remove(op.id);

  if (e.type == SyncConflictType.versionMismatch) {
    final serverVersion = e.serverDocument!['version'] as int? ?? 1;
    await _updateLocalCacheVersion(e.entityType, e.entityId, serverVersion);
  }

  _conflictController.add(SyncConflict(...));
}
```

### 6.4 Version Preservation in Repository

The `BaseCachingRepository.update()` preserves the version from the existing cache to prevent overwriting a version that was corrected during conflict resolution:

```dart
Future<TEntity> update(TEntity entity) async {
  final existing = await findCacheById(getId(entity));
  final cache = toCache(entity);

  if (existing != null) {
    setIsarId(cache, getIsarId(existing));
    // CRITICAL: Preserve version from cache, not from in-memory entity
    preserveVersion(cache, existing);
  }

  await local.db.writeTxn(() async {
    await collection.put(cache);
  });
  // ...
}
```

---

## 7. Data Flow Summary

### 7.1 Write Flow

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          WRITE FLOW SUMMARY                                │
└────────────────────────────────────────────────────────────────────────────┘

                          User Action
                              │
                              ▼
                    ┌─────────────────┐
                    │ AppStateNotifier│
                    │  (e.g., setNote)│
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ CachingRepository│
                    │    update()      │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
     ┌─────────────────┐           ┌─────────────────┐
     │  Write to Isar  │           │  Enqueue Sync   │
     │    (instant)    │           │   Operation     │
     └─────────────────┘           └────────┬────────┘
                                            │
                                            ▼
                                   ┌─────────────────┐
                                   │ triggerSync()   │
                                   │ (fire-and-forget)│
                                   └────────┬────────┘
                                            │
                              ┌─────────────┴─────────────┐
                              │                           │
                        [Connected?]                      │
                              │                           │
                    ┌─────────┴─────────┐                 │
                    │                   │                 │
                  [YES]               [NO]                │
                    │                   │                 │
                    ▼                   ▼                 │
           ┌─────────────────┐  ┌─────────────────┐       │
           │ Process queue   │  │ Queue waits     │       │
           │ → MongoDB sync  │  │ (30s timer)     │       │
           └─────────────────┘  └─────────────────┘       │
                                                          │
                              ▼ ◀──────────────────────────┘
                    ┌─────────────────┐
                    │  UI Updated     │
                    │  (state change) │
                    └─────────────────┘
```

### 7.2 Read Flow

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          READ FLOW SUMMARY                                 │
└────────────────────────────────────────────────────────────────────────────┘

                          UI Request
                       (ref.watch/read)
                              │
                              ▼
                    ┌─────────────────┐
                    │   AppState      │
                    │ (in-memory)     │
                    └─────────────────┘
                              │
                              │
    ┌─────────────────────────┴─────────────────────────┐
    │                                                   │
    │        State is loaded at startup from:           │
    │                                                   │
    │   ┌──────────────────┐    ┌──────────────────┐   │
    │   │ If Online:       │    │ If Offline:      │   │
    │   │ MongoDB → Isar   │    │ Isar only        │   │
    │   │ → AppState       │    │ → AppState       │   │
    │   └──────────────────┘    └──────────────────┘   │
    │                                                   │
    └───────────────────────────────────────────────────┘

    Note: Reads NEVER go directly to MongoDB during normal operation.
          All reads are from in-memory AppState or local Isar cache.
```

---

## 8. Implementation Details

### 8.1 Entity Types and Collections

| Entity Type | Isar Collection | MongoDB Collection |
|-------------|-----------------|-------------------|
| `modul` | `modulCaches` | `moduls` |
| `group` | `groupCaches` | `groups` |
| `dailyNote` | `dailyNoteCaches` | `daily_notes` |
| `academicYear` | `academicYearCaches` | `academic_years` |
| `recurringHoliday` | `recurringHolidayCaches` | `recurring_holidays` |
| `userPreferences` | `userPreferencesCaches` | `user_preferences` |

### 8.2 Sync Operation Lifecycle

```
1. ENQUEUE
   ┌─────────────────────────────────────┐
   │ SyncOperation {                     │
   │   entityType: "dailyNote"           │
   │   entityId: "uuid-abc-123"          │
   │   operationType: "update"           │
   │   payload: "{json...}"              │
   │   timestamp: 2026-02-01T10:00:00Z   │
   │   retryCount: 0                     │
   │ }                                   │
   └─────────────────────────────────────┘
                    │
                    ▼
2. PROCESS (when connected)
                    │
         ┌──────────┴──────────┐
         │                     │
   ┌─────┴─────┐         ┌─────┴─────┐
   │  Success  │         │  Failure  │
   └─────┬─────┘         └─────┬─────┘
         │                     │
         ▼                     ▼
   ┌───────────┐         ┌───────────┐
   │ Remove    │         │ Retry++   │
   │ from      │         │ Store     │
   │ queue     │         │ error     │
   └───────────┘         └─────┬─────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
              ┌─────┴─────┐         ┌─────┴─────┐
              │ retry < 3 │         │ retry ≥ 3 │
              │ Keep in   │         │ Log and   │
              │ queue     │         │ abandon   │
              └───────────┘         └───────────┘
```

### 8.3 File Locations

| Component | File Path |
|-----------|-----------|
| CacheService | `lib/data/services/cache_service.dart` |
| SyncQueue | `lib/data/cache/sync_queue.dart` |
| SyncConflict | `lib/data/cache/sync_conflict.dart` |
| LocalDatasource | `lib/data/datasources/local_datasource.dart` |
| MongoDbDatasource | `lib/data/datasources/mongodb_datasource.dart` |
| BaseCachingRepository | `lib/data/repositories/base_caching_repository.dart` |
| SyncOperation schema | `lib/data/cache/schemas/sync_operation.dart` |
| Cache schemas | `lib/data/cache/schemas/*.dart` |

### 8.4 Status Indicator Behavior

| Condition | Status | LED Color |
|-----------|--------|-----------|
| MongoDB not connected | `offline` | Amber |
| MongoDB connected, queue empty | `online` | Green |
| Executing MongoDB operation | `syncing` | Amber (brief) |
| Queue processing, no active network call | `online` | Green |

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| **Local-First** | Architecture where local storage is the primary data source |
| **Isar** | Flutter-native NoSQL database for local persistence |
| **Optimistic Locking** | Conflict detection using version numbers |
| **Sync Queue** | Persistent queue of operations awaiting remote sync |
| **Cache Service** | Coordinator for local/remote sync |
| **Version Mismatch** | Server has newer version than local |

---

**End of Document**
