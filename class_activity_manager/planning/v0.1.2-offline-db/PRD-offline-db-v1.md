# Offline-First Flutter Architecture Plan

## Hive (Local Cache) + MongoDB (Server)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                          │
│  ┌─────────────┐    ┌─────────────────┐                        │
│  │  Flutter UI │───▶│  BLoC/Provider  │                        │
│  └─────────────┘    └────────┬────────┘                        │
└──────────────────────────────┼──────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────┐
│                      DOMAIN LAYER                               │
│  ┌─────────────┐    ┌────────▼────────┐                        │
│  │  Use Cases  │◀───│ Repository Intf │                        │
│  └─────────────┘    └────────┬────────┘                        │
└──────────────────────────────┼──────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────┐
│                       DATA LAYER                                │
│                 ┌────────────▼───────────┐                     │
│                 │  Repository Implementation │                  │
│                 └─────┬─────────────┬────┘                     │
│        ┌──────────────▼──┐    ┌─────▼──────────────┐          │
│        │ LOCAL DATA SRC  │    │  REMOTE DATA SRC   │          │
│        │  ┌───────────┐  │    │  ┌──────────────┐  │          │
│        │  │Hive Boxes │  │    │  │REST API Client│  │          │
│        │  ├───────────┤  │    │  └──────────────┘  │          │
│        │  │Sync Queue │  │    │                    │          │
│        │  └───────────┘  │    │                    │          │
│        └─────────────────┘    └─────────┬──────────┘          │
└─────────────────────────────────────────┼──────────────────────┘
                                          │
┌─────────────────────────────────────────┼──────────────────────┐
│                  BACKGROUND SERVICES                           │
│  ┌─────────────────────┐    ┌───────────▼─────────┐           │
│  │Connectivity Monitor │───▶│    Sync Service     │           │
│  └─────────────────────┘    └─────────────────────┘           │
└────────────────────────────────────────────────────────────────┘
                                          │
                                          ▼
┌────────────────────────────────────────────────────────────────┐
│                       SERVER SIDE                              │
│  ┌──────────────────┐    ┌─────────────────────┐              │
│  │ Node.js/Python   │───▶│      MongoDB        │              │
│  │    REST API      │    │                     │              │
│  └──────────────────┘    └─────────────────────┘              │
└────────────────────────────────────────────────────────────────┘
```

---

## 2. Hive Box Structure

| Box Name | Purpose | Key Strategy |
|----------|---------|--------------|
| `entities_<collection>` | Cache MongoDB documents | Document `_id` as key |
| `sync_queue` | Track pending changes | Auto-increment int key |
| `sync_metadata` | Last sync timestamps per collection | Collection name as key |
| `settings` | App config, user preferences | String keys |

### Example Box Initialization

```dart
// Conceptual structure - not implementation
await Hive.openBox<Map>('entities_users');
await Hive.openBox<Map>('entities_products');
await Hive.openBox<Map>('sync_queue');
await Hive.openBox<Map>('sync_metadata');
```

---

## 3. Data Flow Strategies

### 3.1 READ Operation Flow

```
┌─────────────────┐
│  Request Data   │
└────────┬────────┘
         │
         ▼
    ┌────────────┐
    │ In Hive    │
    │  Cache?    │
    └─────┬──────┘
      Yes │  No
    ┌─────┴─────┐
    ▼           ▼
┌────────┐  ┌────────┐
│ Return │  │Online? │
│ Cached │  └───┬────┘
└────────┘   Yes│  No
          ┌────┴────┐
          ▼         ▼
    ┌──────────┐ ┌─────────────┐
    │Fetch from│ │Return Empty │
    │   API    │ │  or Stale   │
    └────┬─────┘ └─────────────┘
         │
         ▼
    ┌──────────┐
    │Store in  │
    │  Hive    │
    └────┬─────┘
         │
         ▼
    ┌──────────┐
    │ Return   │
    │  Data    │
    └──────────┘
```

### 3.2 WRITE Operation Flow

```
┌───────────────────────┐
│ Create/Update/Delete  │
└───────────┬───────────┘
            │
            ▼
    ┌───────────────┐
    │ Write to Hive │
    │  (Immediate)  │
    └───────┬───────┘
            │
            ▼
    ┌───────────────┐
    │ Add to Sync   │
    │    Queue      │
    └───────┬───────┘
            │
            ▼
       ┌────────┐
       │Online? │
       └───┬────┘
       Yes │  No
     ┌─────┴─────┐
     ▼           ▼
┌─────────┐  ┌─────────┐
│Push to  │  │Keep in  │
│  API    │  │ Queue   │
└────┬────┘  └─────────┘
     │
     ▼
┌─────────────┐
│Remove from  │
│   Queue     │
└─────────────┘
```

### 3.3 SYNC Process (Connection Restored)

```
Connectivity Monitor ──▶ Sync Service
                              │
                              ▼
                    ┌─────────────────┐
                    │ Get Pending Ops │
                    │ from Sync Queue │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │   FOR EACH PENDING CHANGE   │
              │  ┌──────────────────────┐   │
              │  │ Push Change to API   │   │
              │  └──────────┬───────────┘   │
              │             ▼               │
              │  ┌──────────────────────┐   │
              │  │ API Upserts to Mongo │   │
              │  └──────────┬───────────┘   │
              │             ▼               │
              │  ┌──────────────────────┐   │
              │  │ Update Hive with     │   │
              │  │ Server Response      │   │
              │  └──────────┬───────────┘   │
              │             ▼               │
              │  ┌──────────────────────┐   │
              │  │ Remove from Queue    │   │
              │  └──────────────────────┘   │
              └─────────────────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Fetch Server    │
                    │ Changes Since   │
                    │ Last Sync       │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Merge into      │
                    │ Hive Cache      │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Update Last     │
                    │ Sync Timestamp  │
                    └─────────────────┘
```

---

## 4. Document Schema Enhancement

Each document needs sync metadata fields for proper offline/online coordination:

```json
{
  "_id": "64f1a2b3c4d5e6f7g8h9i0j1",
  
  "name": "Example Document",
  "data": { ... },
  
  "_version": 3,
  "_createdAt": "2025-01-15T10:30:00Z",
  "_updatedAt": "2025-01-31T14:22:00Z",
  "_syncStatus": "synced",
  "_deletedAt": null
}
```

### Field Definitions

| Field | Type | Purpose |
|-------|------|---------|
| `_id` | String | MongoDB ObjectId (used as Hive key) |
| `_version` | Integer | Optimistic concurrency control |
| `_createdAt` | ISO String | Document creation timestamp |
| `_updatedAt` | ISO String | Last modification timestamp |
| `_syncStatus` | Enum | `synced` \| `pending` \| `conflict` |
| `_deletedAt` | ISO String? | Soft delete timestamp (null = active) |

---

## 5. Sync Queue Entry Structure

```json
{
  "id": 1,
  "type": "UPDATE",
  "collection": "users",
  "documentId": "64f1a2b3c4d5e6f7g8h9i0j1",
  "data": {
    "name": "Updated Name",
    "_version": 4
  },
  "timestamp": "2025-01-31T14:25:00Z",
  "retryCount": 0
}
```

### Operation Types

| Type | Description |
|------|-------------|
| `CREATE` | New document created offline |
| `UPDATE` | Existing document modified |
| `DELETE` | Document marked for deletion |

---

## 6. Conflict Resolution Strategy

| Scenario | Resolution | Implementation |
|----------|------------|----------------|
| Same doc modified locally + server | **Last-write-wins** using `_updatedAt` | Compare timestamps, keep newer |
| Local delete, server update | Server update wins | Restore document locally |
| Server delete, local update | Mark as conflict | Prompt user for decision |
| Version mismatch | Fetch server version | Merge fields or overwrite |

### Conflict Detection Logic

```
IF local._version != server._version THEN
    IF local._updatedAt > server._updatedAt THEN
        → Push local changes (force)
    ELSE IF server._updatedAt > local._updatedAt THEN
        → Accept server version
    ELSE
        → Mark as conflict, require user resolution
```

---

## 7. Key Components

### 7.1 Data Layer Components

| Component | Responsibility |
|-----------|----------------|
| `HiveLocalDataSource` | CRUD on Hive boxes, mirrors MongoDB API |
| `MongoRemoteDataSource` | REST API calls to backend server |
| `RepositoryImpl` | Orchestrates local-first reads, queues writes |
| `DataSourceInterface` | Abstract contract both sources implement |

### 7.2 Sync Infrastructure

| Component | Responsibility |
|-----------|----------------|
| `SyncQueue` | Hive box storing pending operations |
| `SyncMetadataBox` | Tracks `lastSyncTimestamp` per collection |
| `SyncService` | Processes queue, handles push/pull logic |
| `ConnectivityMonitor` | Listens for network state changes |
| `ConflictResolver` | Handles sync conflicts per strategy |

### 7.3 Utilities

| Component | Responsibility |
|-----------|----------------|
| `UuidGenerator` | Generate document IDs when offline |
| `TimestampService` | Consistent timestamp generation |
| `RetryPolicy` | Exponential backoff for failed syncs |

---

## 8. Flutter Packages Required

| Package | Version | Purpose |
|---------|---------|---------|
| `hive` | ^2.2.3 | Local key-value/document storage |
| `hive_flutter` | ^1.1.0 | Flutter-specific Hive initialization |
| `connectivity_plus` | ^5.0.0 | Network state monitoring |
| `uuid` | ^4.2.0 | Generate offline document IDs |
| `dio` | ^5.4.0 | HTTP client for REST API |
| `flutter_bloc` | ^8.1.0 | State management (or `riverpod`) |
| `equatable` | ^2.0.5 | Value equality for models |
| `json_annotation` | ^4.8.0 | JSON serialization helpers |

---

## 9. Minimal Code Change Strategy

### Goal: Keep existing business logic and UI unchanged

Since your app already uses MongoDB, create an **abstract interface** that both Hive and MongoDB implementations conform to:

```
┌─────────────────────────────────────────────────────────┐
│                 DataSourceInterface                     │
│  ┌───────────────────────────────────────────────────┐ │
│  │  + findById(collection, id)                       │ │
│  │  + find(collection, filter, options)              │ │
│  │  + insert(collection, document)                   │ │
│  │  + update(collection, id, data)                   │ │
│  │  + delete(collection, id)                         │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────┬───────────────────┬───────────────────┘
                  │                   │
        ┌─────────▼─────────┐ ┌───────▼─────────┐
        │ HiveLocalSource   │ │ MongoRemoteSource│
        │ (implements)      │ │ (implements)     │
        └───────────────────┘ └──────────────────┘
```

### Repository Pattern

```
Repository
    │
    ├── READ  → Hive first, fallback to API if miss/stale
    │
    ├── WRITE → Hive immediately + add to sync queue
    │
    └── SYNC  → Background service processes queue
```

### What Changes vs. What Stays

| Layer | Changes? | Notes |
|-------|----------|-------|
| UI/Widgets | ❌ No | Same data models |
| BLoC/Provider | ❌ No | Same repository interface |
| Use Cases | ❌ No | Same repository interface |
| Repository Interface | ❌ No | Define if not exists |
| Repository Impl | ✅ Yes | Add local-first logic |
| Data Sources | ✅ Yes | Add Hive implementation |
| Models | ✅ Minor | Add sync metadata fields |

---

## 10. Implementation Phases

### Phase 1: Foundation
- [ ] Define `DataSourceInterface`
- [ ] Add sync metadata fields to models
- [ ] Set up Hive boxes structure
- [ ] Implement `HiveLocalDataSource`

### Phase 2: Repository Layer
- [ ] Refactor `RepositoryImpl` for local-first reads
- [ ] Implement write-through to Hive + queue
- [ ] Add connectivity detection

### Phase 3: Sync Infrastructure
- [ ] Build `SyncQueue` management
- [ ] Implement `SyncService` with push/pull
- [ ] Add `ConnectivityMonitor` triggers
- [ ] Implement conflict resolution

### Phase 4: Testing & Polish
- [ ] Unit tests for sync logic
- [ ] Integration tests (offline scenarios)
- [ ] Handle edge cases (app kill during sync, etc.)
- [ ] Add sync status indicators to UI

---

## 11. API Endpoint Requirements

Your backend needs these endpoints to support sync:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `GET /api/{collection}` | GET | Fetch documents (with filters) |
| `GET /api/{collection}/{id}` | GET | Fetch single document |
| `POST /api/{collection}` | POST | Create document |
| `PUT /api/{collection}/{id}` | PUT | Update document |
| `DELETE /api/{collection}/{id}` | DELETE | Soft delete document |
| `GET /api/{collection}/changes?since={timestamp}` | GET | **Fetch changes since last sync** |
| `POST /api/{collection}/batch` | POST | **Batch upsert for sync** |

---

## 12. Error Handling & Edge Cases

| Scenario | Handling |
|----------|----------|
| Sync fails mid-way | Keep remaining items in queue, retry with backoff |
| App killed during sync | Queue persists in Hive, resume on next launch |
| Server returns 409 Conflict | Trigger conflict resolution flow |
| Network timeout | Increment retry count, exponential backoff |
| Hive corruption | Clear cache, force full sync from server |
| Queue grows too large | Alert user, prioritize critical collections |

---

## 13. Future Considerations

- **Real-time sync**: Add WebSocket/SSE for instant server updates
- **Selective sync**: Only sync certain collections or date ranges
- **Compression**: Compress large documents before sync
- **Encryption**: Encrypt sensitive data in Hive at rest
- **Multi-device**: Handle same user on multiple devices

---

*Document created: January 31, 2025*
*Architecture: Offline-First with Hive + MongoDB*