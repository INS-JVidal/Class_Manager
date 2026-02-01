# Class Activity Manager - Architecture Report v0.1.4

**Date:** 2026-01-31
**Version:** v0.1.4
**Lines of Code:** ~8,000 (49 Dart files)

---

## Table of Contents

1. [Overview](#1-overview)
2. [High-Level Architecture](#2-high-level-architecture)
3. [Layer Diagram](#3-layer-diagram)
4. [State Management](#4-state-management)
5. [Data Layer](#5-data-layer)
6. [Domain Models](#6-domain-models)
7. [Presentation Layer](#7-presentation-layer)
8. [Routing](#8-routing)
9. [Initialization Flow](#9-initialization-flow)
10. [Sync Mechanism](#10-sync-mechanism)
11. [File Structure](#11-file-structure)

---

## 1. Overview

Class Activity Manager is a Flutter desktop application for managing professional training modules, learning outcomes (RAs - Resultats d'Aprenentatge), and classroom activities in the Catalan education system.

### Key Characteristics

- **Offline-First Architecture:** Local Isar cache with MongoDB sync
- **State Management:** Riverpod with StateNotifier pattern
- **Platform:** Linux/macOS/Windows desktop
- **Localization:** Catalan (hardcoded)

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                         │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐    │
│  │ Dashboard │  │  Calendar │  │   Moduls  │  │   Grups   │    │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘    │
│        │              │              │              │           │
│        └──────────────┴──────────────┴──────────────┘           │
│                              │                                  │
│                     ┌────────┴────────┐                         │
│                     │    AppShell     │                         │
│                     │  (Navigation)   │                         │
│                     └────────┬────────┘                         │
└──────────────────────────────┼──────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────┐
│                      STATE LAYER (Riverpod)                     │
│                     ┌────────┴────────┐                         │
│                     │   AppState      │                         │
│                     │   Notifier      │                         │
│                     └────────┬────────┘                         │
│                              │                                  │
│         ┌────────────────────┼────────────────────┐             │
│         │                    │                    │             │
│  ┌──────┴──────┐      ┌──────┴──────┐     ┌──────┴──────┐      │
│  │   Caching   │      │    Sync     │     │   Cache     │      │
│  │   Repos     │      │    Queue    │     │   Service   │      │
│  └──────┬──────┘      └──────┬──────┘     └──────┬──────┘      │
└─────────┼────────────────────┼───────────────────┼──────────────┘
          │                    │                   │
┌─────────┼────────────────────┼───────────────────┼──────────────┐
│         │            DATA LAYER                  │              │
│         │                    │                   │              │
│  ┌──────┴──────┐      ┌──────┴──────┐     ┌──────┴──────┐      │
│  │    Isar     │      │    Isar     │     │   MongoDB   │      │
│  │   Cache     │      │   Queue     │     │   Remote    │      │
│  └─────────────┘      └─────────────┘     └─────────────┘      │
│                                                                 │
│       LOCAL (Always Available)              REMOTE (Optional)   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Layer Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                                                                    │
│   lib/                                                             │
│   ├── presentation/     UI Layer (4,581 LOC)                       │
│   │   ├── pages/           Page widgets                            │
│   │   ├── shell/           Navigation drawer                       │
│   │   └── widgets/         Reusable components                     │
│   │                                                                │
│   ├── state/            State Layer (885 LOC)                      │
│   │   ├── app_state.dart   AppStateNotifier                        │
│   │   └── providers.dart   Riverpod providers                      │
│   │                                                                │
│   ├── data/             Data Layer (12,526 LOC)                    │
│   │   ├── cache/           Isar schemas                            │
│   │   ├── datasources/     Local + MongoDB                         │
│   │   ├── repositories/    Caching + Remote                        │
│   │   └── services/        CacheService, DB                        │
│   │                                                                │
│   ├── models/           Domain Layer (569 LOC)                     │
│   │   ├── modul.dart       Professional module                     │
│   │   ├── ra.dart          Learning outcome                        │
│   │   ├── group.dart       Student class                           │
│   │   ├── daily_note.dart  Session notes                           │
│   │   └── ...              Other entities                          │
│   │                                                                │
│   ├── router/           Routing (162 LOC)                          │
│   │   └── app_router.dart  GoRouter config                         │
│   │                                                                │
│   └── core/             Utilities (250 LOC)                        │
│       ├── theme/           Material 3 theme                        │
│       └── audit/           File audit logger                       │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## 4. State Management

### AppState Structure

```
AppState (Immutable)
│
├── currentYear: AcademicYear?
├── recurringHolidays: List<RecurringHoliday>
├── groups: List<Group>
├── moduls: List<Modul>
├── dailyNotes: List<DailyNote>
├── selectedCicleIds: Set<String>
├── isLoading: bool
└── isInitialized: bool
```

### Data Flow Pattern

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│     UI      │────>│  AppStateNotifier │────>│  Local Cache    │
│   Action    │     │     Method        │     │    (Isar)       │
└─────────────┘     └────────┬─────────┘     └─────────────────┘
                             │
                             v
                    ┌────────────────┐
                    │   Sync Queue   │
                    │   (Enqueue)    │
                    └────────┬───────┘
                             │
                             v
                    ┌────────────────┐
                    │  Update State  │
                    │  (copyWith)    │
                    └────────┬───────┘
                             │
                             v
                    ┌────────────────┐
                    │  Trigger Sync  │
                    │  (Background)  │
                    └────────────────┘
```

### Provider Hierarchy

```
main.dart
│
├── databaseServiceProvider ─────> DatabaseService? (nullable)
├── localDatasourceProvider ─────> LocalDatasource (Isar)
├── syncQueueProvider ───────────> SyncQueue
├── cacheServiceProvider ────────> CacheService
│
├── cacheStatusProvider ─────────> Stream<CacheStatus>
├── pendingSyncCountProvider ────> Future<int>
│
└── appStateProvider ────────────> AppStateNotifier
                                       │
                                       └── Uses all above providers
```

---

## 5. Data Layer

### Offline-First Flow

```
                    WRITE OPERATION
                          │
                          v
            ┌─────────────────────────┐
            │   Caching Repository    │
            │   (e.g., CachingModul)  │
            └───────────┬─────────────┘
                        │
           ┌────────────┼────────────┐
           v            v            v
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │  Write   │  │  Enqueue │  │  Return  │
    │  Isar    │  │  Sync Op │  │  to UI   │
    └──────────┘  └────┬─────┘  └──────────┘
                       │
                       v
              ┌────────────────┐
              │  Background    │
              │  Sync Loop     │
              │  (30 sec)      │
              └────────┬───────┘
                       │
           ┌───────────┴───────────┐
           v                       v
    ┌──────────────┐        ┌──────────────┐
    │  Connected?  │───No──>│   Stay in    │
    │              │        │    Queue     │
    └──────┬───────┘        └──────────────┘
           │ Yes
           v
    ┌──────────────┐
    │   Execute    │
    │   MongoDB    │
    │   Operation  │
    └──────┬───────┘
           │
           v
    ┌──────────────┐
    │   Remove     │
    │   from Queue │
    └──────────────┘
```

### Repository Structure

```
CACHING REPOSITORIES (Local-First)
│
├── CachingModulRepository
│   ├── insert(Modul) ─────> Isar + Queue
│   ├── update(Modul) ─────> Isar + Queue
│   ├── delete(id) ────────> Isar + Queue
│   ├── findByCode(code)
│   └── syncFromRemote(List<Modul>)
│
├── CachingGroupRepository
├── CachingDailyNoteRepository
├── CachingAcademicYearRepository
└── CachingRecurringHolidayRepository

REMOTE REPOSITORIES (MongoDB Direct)
│
├── ModulRepository
├── GroupRepository
├── DailyNoteRepository
├── AcademicYearRepository
└── RecurringHolidayRepository
```

### Isar Cache Schemas

```
LocalDatasource (Isar)
│
├── ModulCache
│   ├── id (Isar auto-increment)
│   ├── modulId (UUID)
│   ├── code, name, description
│   ├── totalHours
│   ├── rasJson (JSON string)
│   └── cicleCodesJson
│
├── GroupCache
│   ├── groupId, name, notes
│   ├── academicYearId
│   ├── moduleIdsJson
│   └── color
│
├── DailyNoteCache
│   ├── noteId, raId, modulId, groupId
│   ├── date
│   ├── plannedContent, actualContent
│   └── completed
│
├── AcademicYearCache
│   ├── yearId, name
│   ├── startDate, endDate
│   ├── vacationPeriodsJson
│   └── isActive
│
├── RecurringHolidayCache
│   ├── holidayId, name
│   ├── month, day
│   └── isEnabled
│
└── SyncOperation
    ├── entityType, entityId
    ├── operationType (insert/update/delete)
    ├── payload (JSON)
    ├── timestamp
    ├── retryCount
    └── lastError
```

---

## 6. Domain Models

### Entity Relationships

```
┌─────────────────┐
│  AcademicYear   │
│  ─────────────  │
│  id             │
│  name           │
│  startDate      │◄─────────────────────────┐
│  endDate        │                          │
│  isActive       │                          │
│  vacationPeriods│──┐                       │
└─────────────────┘  │                       │
                     │                       │
┌─────────────────┐  │     ┌─────────────────┐
│ VacationPeriod  │◄─┘     │      Group      │
│  ─────────────  │        │  ─────────────  │
│  id             │        │  id             │
│  name           │        │  name           │
│  startDate      │        │  academicYearId │────┘
│  endDate        │        │  moduleIds      │────────┐
└─────────────────┘        │  color          │        │
                           └─────────────────┘        │
                                   │                  │
                                   │ groupId          │
                                   v                  v
┌─────────────────┐        ┌─────────────────┐  ┌─────────────────┐
│   DailyNote     │        │      Modul      │◄─┤   (many-to-many)│
│  ─────────────  │        │  ─────────────  │  └─────────────────┘
│  id             │        │  id             │
│  groupId        │────────│  code (MP06)    │
│  modulId        │────────│  name           │
│  raId           │───┐    │  totalHours     │
│  date           │   │    │  ras            │──┐
│  plannedContent │   │    │  cicleCodes     │  │
│  actualContent  │   │    └─────────────────┘  │
│  completed      │   │                         │
└─────────────────┘   │    ┌─────────────────┐  │
                      │    │       RA        │◄─┘
                      └───>│  ─────────────  │
                           │  id             │
                           │  number (RA1)   │
                           │  code           │
                           │  title          │
                           │  durationHours  │
                           │  startDate      │
                           │  endDate        │
                           │  criteris       │──┐
                           └─────────────────┘  │
                                                │
                           ┌─────────────────┐  │
                           │CriteriAvaluacio │◄─┘
                           │  ─────────────  │
                           │  id             │
                           │  code           │
                           │  description    │
                           └─────────────────┘

┌─────────────────┐
│RecurringHoliday │   (Independent - yearly holidays)
│  ─────────────  │
│  id             │
│  name           │
│  month, day     │
│  isEnabled      │
└─────────────────┘
```

---

## 7. Presentation Layer

### Page Components

```
PAGES (ConsumerWidget / ConsumerStatefulWidget)
│
├── DashboardPage
│   ├── Today's Sessions (active RAs for today)
│   └── Active RAs Grid (all RAs with date ranges)
│
├── CalendarPage
│   ├── Monthly calendar view
│   ├── Vacation periods
│   └── Recurring holidays
│
├── ModulsPage
│   ├── Module list
│   ├── Module detail
│   └── RA configuration
│
├── GrupsPage
│   ├── Group list
│   └── Group-module relationships
│
├── DailyNotesPage
│   ├── Session notes by group/RA
│   └── Markdown editor
│
├── ConfiguracioPage
│   ├── Academic year settings
│   ├── Vacation periods
│   └── Recurring holidays
│
└── SetupCurriculumPage
    └── Import from YAML
```

### Widget Tree

```
MaterialApp
│
└── AppShell (ShellRoute)
    │
    ├── NavigationDrawer
    │   ├── SyncStatusIndicator
    │   │   └── [LED dot] + "online"/"local"
    │   └── Navigation Destinations (9)
    │
    └── [Page Content]
        └── ConsumerWidget
            └── ref.watch(appStateProvider)
```

---

## 8. Routing

### GoRouter Configuration

```
/                          DashboardPage
│
├── /calendar              CalendarPage
│
├── /moduls                ModulsListPage
│   ├── /moduls/edit/:id   ModulFormPage
│   └── /moduls/:id        ModulDetailPage
│       ├── /ra-config     RaConfigPage
│       ├── /ra/new        RAFormPage
│       └── /ra/edit/:raId RAFormPage
│
├── /grups                 GrupsListPage
│   ├── /grups/new         GroupFormPage
│   └── /grups/edit/:id    GroupFormPage
│
├── /daily-notes           DailyNotesPage
│
├── /configuracio          ConfiguracioPage
│
├── /setup-curriculum      SetupCurriculumPage
│
├── /tasques               PlaceholderPage
├── /informes              PlaceholderPage
└── /arxiu                 PlaceholderPage
```

---

## 9. Initialization Flow

```
main()
│
├── 1. SingleInstanceGuard.tryAcquire()
│      └── File lock at ~/.local/share/class_activity_manager/
│
├── 2. Load .env
│      └── MONGO_URI
│
├── 3. Initialize LocalDatasource (Isar)
│      └── Always succeeds
│
├── 4. Connect MongoDB (optional)
│      ├── Success ──> DatabaseService created
│      └── Failure ──> App continues offline
│
├── 5. Create Infrastructure
│      ├── SyncQueue(localDatasource)
│      ├── CacheService(local, remote, queue)
│      └── await cacheService.initialize()
│
├── 6. Setup AuditLogger
│      └── FileAuditLogger to XDG_STATE_HOME
│
├── 7. Override Providers
│      ├── databaseServiceProvider
│      ├── localDatasourceProvider
│      ├── syncQueueProvider
│      ├── cacheServiceProvider
│      └── appStateProvider
│
└── 8. Launch App
       │
       └── _AppWithDatabaseInit
           │
           ├── Show loading screen
           │
           ├── addPostFrameCallback()
           │   └── appStateProvider.notifier.loadFromDatabase()
           │       │
           │       ├── If MongoDB connected:
           │       │   └── Pull from remote, cache locally
           │       │
           │       └── If offline:
           │           └── Load from Isar cache
           │
           └── Show ClassActivityManagerApp
```

---

## 10. Sync Mechanism

### Status States

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   ONLINE    │     │   OFFLINE   │     │   SYNCING   │
│   (green)   │     │   (amber)   │     │   (amber)   │
│             │     │             │     │             │
│ Connected   │     │ No MongoDB  │     │ Processing  │
│ Queue empty │     │ Using cache │     │ queue ops   │
└─────────────┘     └─────────────┘     └─────────────┘
       ^                   │                   │
       │                   │                   │
       └───────────────────┴───────────────────┘
              Transitions via CacheService
```

### Sync Operation Lifecycle

```
1. ENQUEUE
   ┌─────────────────────────────────────┐
   │ SyncOperation {                     │
   │   entityType: "modul"               │
   │   entityId: "uuid-..."              │
   │   operationType: "insert"           │
   │   payload: "{...json...}"           │
   │   timestamp: 2026-01-31T17:00:00Z   │
   │   retryCount: 0                     │
   │ }                                   │
   └─────────────────────────────────────┘
                    │
                    v
2. PROCESS (every 30 seconds if connected)
                    │
        ┌───────────┴───────────┐
        v                       v
   ┌─────────┐            ┌─────────┐
   │ Success │            │ Failure │
   └────┬────┘            └────┬────┘
        │                      │
        v                      v
   ┌─────────┐            ┌─────────┐
   │ Remove  │            │ Retry   │
   │ from    │            │ count++ │
   │ queue   │            │         │
   └─────────┘            └────┬────┘
                               │
                    ┌──────────┴──────────┐
                    v                     v
              ┌─────────┐           ┌─────────┐
              │ retry<3 │           │ retry>=3│
              │ Keep in │           │ Log and │
              │ queue   │           │ abandon │
              └─────────┘           └─────────┘
```

### MongoDB Collection Mapping

```
Entity Type          MongoDB Collection
─────────────        ──────────────────
modul           ──>  moduls
group           ──>  groups
dailyNote       ──>  daily_notes
academicYear    ──>  academic_years
recurringHoliday ──> recurring_holidays
```

---

## 11. File Structure

```
lib/
├── main.dart                    (167 lines)  Entry point
├── app.dart                     (34 lines)   Root widget
│
├── core/                        (250 lines)
│   ├── audit/
│   │   ├── audit_logger.dart               Interface
│   │   └── file_audit_logger.dart          Implementation
│   ├── theme/
│   │   └── app_theme.dart                  Material 3
│   └── single_instance_guard.dart          File lock
│
├── data/                        (12,526 lines)
│   ├── cache/
│   │   ├── schemas/                        Isar schemas
│   │   │   ├── modul_cache.dart
│   │   │   ├── group_cache.dart
│   │   │   ├── daily_note_cache.dart
│   │   │   ├── academic_year_cache.dart
│   │   │   ├── recurring_holiday_cache.dart
│   │   │   ├── sync_operation.dart
│   │   │   └── *.g.dart                    Generated
│   │   └── sync_queue.dart                 Queue operations
│   ├── datasources/
│   │   ├── local_datasource.dart           Isar
│   │   └── mongodb_datasource.dart         MongoDB
│   ├── repositories/
│   │   ├── caching_*.dart                  Local-first
│   │   └── *_repository.dart               Remote
│   └── services/
│       ├── cache_service.dart              Sync coordinator
│       ├── database_service.dart           Repo aggregator
│       └── curriculum_service.dart         YAML import
│
├── models/                      (569 lines)
│   ├── modul.dart
│   ├── ra.dart
│   ├── criteri_avaluacio.dart
│   ├── group.dart
│   ├── daily_note.dart
│   ├── academic_year.dart
│   ├── vacation_period.dart
│   └── recurring_holiday.dart
│
├── presentation/                (4,581 lines)
│   ├── pages/
│   │   ├── dashboard_page.dart
│   │   ├── calendar_page.dart
│   │   ├── moduls_page.dart
│   │   ├── grups_page.dart
│   │   ├── daily_notes_page.dart
│   │   ├── configuracio_page.dart
│   │   ├── setup_curriculum_page.dart
│   │   ├── ra_config_page.dart
│   │   └── placeholder_page.dart
│   ├── shell/
│   │   └── app_shell.dart
│   └── widgets/
│       ├── sync_status_indicator.dart
│       ├── markdown_text_field.dart
│       └── dual_date_picker.dart
│
├── router/                      (162 lines)
│   └── app_router.dart
│
└── state/                       (885 lines)
    ├── app_state.dart
    └── providers.dart
```

---

## Summary

| Aspect | Implementation |
|--------|----------------|
| **State** | Riverpod StateNotifier, immutable AppState |
| **Persistence** | Offline-first: Isar local + MongoDB remote |
| **Sync** | Background queue with 30-sec polling |
| **Routing** | GoRouter with nested routes |
| **UI** | Material 3, ConsumerWidget pattern |
| **Audit** | File-based logging with trace IDs |

### Strengths

- Instant UI feedback (local-first writes)
- Network resilient (works offline)
- Automatic sync recovery
- No data loss (queued operations)
- Clean layer separation

### Current Limitations

- No conflict detection for concurrent edits
- No selective sync (all or nothing)
- Placeholder pages not implemented
- No i18n (hardcoded Catalan)
