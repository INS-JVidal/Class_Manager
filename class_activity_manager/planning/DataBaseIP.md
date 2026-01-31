# Implementation Plan Document - Flutter MongoDB Integration

## Goal
1. Add MongoDB packages to Flutter app
2. Implement JSON serialization for all domain models
3. Create repository pattern for database operations
4. Integrate persistence into AppState

---

## Part 1: Dependencies

### Packages to Add (`pubspec.yaml`)

```yaml
dependencies:
  mongo_dart: ^0.10.3      # MongoDB driver for Dart
  flutter_dotenv: ^5.1.0   # Environment variable loading
```

---

## Part 2: Model Serialization

### Implementation Order (dependency-based)

**Layer 1 - No dependencies:**
- `CriteriAvaluacio`
- `RecurringHoliday`
- `VacationPeriod`

**Layer 2 - Depends on Layer 1:**
- `RA` (contains `List<CriteriAvaluacio>`)

**Layer 3 - Depends on Layer 2:**
- `Modul` (contains `List<RA>`)
- `AcademicYear` (contains `List<VacationPeriod>`)

**Layer 4 - References only:**
- `Group`
- `DailyNote`

---

### Model: CriteriAvaluacio

**Fields:**
| Field | Type | MongoDB |
|-------|------|---------|
| id | String | _id (ObjectId as string) |
| code | String | code |
| description | String | description |
| order | int | order |

**Serialization:**
```dart
Map<String, dynamic> toJson() => {
  '_id': id,
  'code': code,
  'description': description,
  'order': order,
};

factory CriteriAvaluacio.fromJson(Map<String, dynamic> json) => CriteriAvaluacio(
  id: json['_id']?.toString() ?? const Uuid().v4(),
  code: json['code'] as String,
  description: json['description'] as String,
  order: json['order'] as int? ?? 0,
);
```

---

### Model: RecurringHoliday

**Fields:**
| Field | Type | MongoDB |
|-------|------|---------|
| id | String | _id |
| name | String | name |
| month | int | month |
| day | int | day |
| isEnabled | bool | isEnabled |

**Serialization:**
```dart
Map<String, dynamic> toJson() => {
  '_id': id,
  'name': name,
  'month': month,
  'day': day,
  'isEnabled': isEnabled,
};

factory RecurringHoliday.fromJson(Map<String, dynamic> json) => RecurringHoliday(
  id: json['_id']?.toString() ?? const Uuid().v4(),
  name: json['name'] as String,
  month: json['month'] as int,
  day: json['day'] as int,
  isEnabled: json['isEnabled'] as bool? ?? true,
);
```

---

### Model: VacationPeriod

**Fields:**
| Field | Type | MongoDB |
|-------|------|---------|
| id | String | _id |
| name | String | name |
| startDate | DateTime | startDate (ISODate) |
| endDate | DateTime | endDate (ISODate) |
| note | String? | note |

**Serialization:**
```dart
Map<String, dynamic> toJson() => {
  '_id': id,
  'name': name,
  'startDate': startDate.toIso8601String(),
  'endDate': endDate.toIso8601String(),
  if (note != null) 'note': note,
};

factory VacationPeriod.fromJson(Map<String, dynamic> json) => VacationPeriod(
  id: json['_id']?.toString() ?? const Uuid().v4(),
  name: json['name'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  note: json['note'] as String?,
);
```

---

### Model: RA

**Fields:**
| Field | Type | MongoDB |
|-------|------|---------|
| id | String | _id |
| number | int | number |
| code | String | code |
| title | String | title |
| description | String? | description |
| durationHours | int | durationHours |
| order | int | order |
| criterisAvaluacio | List<CriteriAvaluacio> | criterisAvaluacio (embedded) |
| startDate | DateTime? | startDate |
| endDate | DateTime? | endDate |

**Serialization:**
```dart
Map<String, dynamic> toJson() => {
  '_id': id,
  'number': number,
  'code': code,
  'title': title,
  if (description != null) 'description': description,
  'durationHours': durationHours,
  'order': order,
  'criterisAvaluacio': criterisAvaluacio.map((ca) => ca.toJson()).toList(),
  if (startDate != null) 'startDate': startDate!.toIso8601String(),
  if (endDate != null) 'endDate': endDate!.toIso8601String(),
};

factory RA.fromJson(Map<String, dynamic> json) => RA(
  id: json['_id']?.toString() ?? const Uuid().v4(),
  number: json['number'] as int,
  code: json['code'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  durationHours: json['durationHours'] as int,
  order: json['order'] as int? ?? 0,
  criterisAvaluacio: (json['criterisAvaluacio'] as List<dynamic>?)
      ?.map((e) => CriteriAvaluacio.fromJson(e as Map<String, dynamic>))
      .toList() ?? [],
  startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
  endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
);
```

---

### Model: Modul

**Fields:**
| Field | Type | MongoDB |
|-------|------|---------|
| id | String | _id |
| code | String | code (unique index) |
| name | String | name |
| description | String? | description |
| totalHours | int | totalHours |
| objectives | List<String> | objectives |
| officialReference | String? | officialReference |
| ras | List<RA> | ras (embedded) |
| cicleCodes | List<String> | cicleCodes |

**Serialization:**
```dart
Map<String, dynamic> toJson() => {
  '_id': id,
  'code': code,
  'name': name,
  if (description != null) 'description': description,
  'totalHours': totalHours,
  'objectives': objectives,
  if (officialReference != null) 'officialReference': officialReference,
  'ras': ras.map((ra) => ra.toJson()).toList(),
  'cicleCodes': cicleCodes,
};

factory Modul.fromJson(Map<String, dynamic> json) => Modul(
  id: json['_id']?.toString() ?? const Uuid().v4(),
  code: json['code'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  totalHours: json['totalHours'] as int,
  objectives: (json['objectives'] as List<dynamic>?)?.cast<String>() ?? [],
  officialReference: json['officialReference'] as String?,
  ras: (json['ras'] as List<dynamic>?)
      ?.map((e) => RA.fromJson(e as Map<String, dynamic>))
      .toList() ?? [],
  cicleCodes: (json['cicleCodes'] as List<dynamic>?)?.cast<String>() ?? [],
);
```

---

### Model: AcademicYear

**Fields:**
| Field | Type | MongoDB |
|-------|------|---------|
| id | String | _id |
| name | String | name |
| startDate | DateTime | startDate |
| endDate | DateTime | endDate |
| vacationPeriods | List<VacationPeriod> | vacationPeriods (embedded) |
| isActive | bool | isActive |

**Serialization:**
```dart
Map<String, dynamic> toJson() => {
  '_id': id,
  'name': name,
  'startDate': startDate.toIso8601String(),
  'endDate': endDate.toIso8601String(),
  'vacationPeriods': vacationPeriods.map((vp) => vp.toJson()).toList(),
  'isActive': isActive,
};

factory AcademicYear.fromJson(Map<String, dynamic> json) => AcademicYear(
  id: json['_id']?.toString() ?? const Uuid().v4(),
  name: json['name'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  vacationPeriods: (json['vacationPeriods'] as List<dynamic>?)
      ?.map((e) => VacationPeriod.fromJson(e as Map<String, dynamic>))
      .toList() ?? [],
  isActive: json['isActive'] as bool? ?? true,
);
```

---

### Model: Group

**Fields:**
| Field | Type | MongoDB |
|-------|------|---------|
| id | String | _id |
| name | String | name |
| notes | String? | notes |
| academicYearId | String? | academicYearId (ObjectId ref) |
| moduleIds | List<String> | moduleIds (array of ObjectId refs) |

**Serialization:**
```dart
Map<String, dynamic> toJson() => {
  '_id': id,
  'name': name,
  if (notes != null) 'notes': notes,
  if (academicYearId != null) 'academicYearId': academicYearId,
  'moduleIds': moduleIds,
};

factory Group.fromJson(Map<String, dynamic> json) => Group(
  id: json['_id']?.toString() ?? const Uuid().v4(),
  name: json['name'] as String,
  notes: json['notes'] as String?,
  academicYearId: json['academicYearId']?.toString(),
  moduleIds: (json['moduleIds'] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList() ?? [],
);
```

---

### Model: DailyNote

**Fields:**
| Field | Type | MongoDB |
|-------|------|---------|
| id | String | _id |
| raId | String | raId (ref) |
| modulId | String | modulId (ref) |
| groupId | String | groupId (ref) |
| date | DateTime | date |
| plannedContent | String? | plannedContent |
| actualContent | String? | actualContent |
| notes | String? | notes |
| completed | bool | completed |

**Serialization:**
```dart
Map<String, dynamic> toJson() => {
  '_id': id,
  'raId': raId,
  'modulId': modulId,
  'groupId': groupId,
  'date': date.toIso8601String(),
  if (plannedContent != null) 'plannedContent': plannedContent,
  if (actualContent != null) 'actualContent': actualContent,
  if (notes != null) 'notes': notes,
  'completed': completed,
};

factory DailyNote.fromJson(Map<String, dynamic> json) => DailyNote(
  id: json['_id']?.toString() ?? const Uuid().v4(),
  raId: json['raId'] as String,
  modulId: json['modulId'] as String,
  groupId: json['groupId'] as String,
  date: DateTime.parse(json['date'] as String),
  plannedContent: json['plannedContent'] as String?,
  actualContent: json['actualContent'] as String?,
  notes: json['notes'] as String?,
  completed: json['completed'] as bool? ?? false,
);
```

---

## Part 3: Repository Layer

### Directory Structure

```
lib/data/
├── datasources/
│   └── mongodb_datasource.dart    # Connection & raw operations
├── repositories/
│   ├── academic_year_repository.dart
│   ├── group_repository.dart
│   ├── modul_repository.dart
│   ├── daily_note_repository.dart
│   └── recurring_holiday_repository.dart
└── services/
    └── database_service.dart      # High-level DB service
```

---

### MongoDB Datasource

**Responsibilities:**
- Connection management (open/close)
- Connection string from environment
- Raw collection access

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDbDatasource {
  Db? _db;

  bool get isConnected => _db?.isConnected ?? false;

  Future<void> connect() async {
    final uri = dotenv.env['MONGO_URI']!;
    _db = await Db.create(uri);
    await _db!.open();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  DbCollection collection(String name) {
    if (_db == null || !_db!.isConnected) {
      throw StateError('Database not connected');
    }
    return _db!.collection(name);
  }
}
```

---

### Repository Interface

Each repository implements CRUD operations:

```dart
abstract class Repository<T> {
  Future<List<T>> findAll();
  Future<T?> findById(String id);
  Future<T> insert(T entity);
  Future<T> update(T entity);
  Future<void> delete(String id);
}
```

---

### ModulRepository

```dart
import 'package:mongo_dart/mongo_dart.dart';
import '../datasources/mongodb_datasource.dart';
import '../../models/modul.dart';

class ModulRepository implements Repository<Modul> {
  final MongoDbDatasource _datasource;

  ModulRepository(this._datasource);

  DbCollection get _collection => _datasource.collection('moduls');

  @override
  Future<List<Modul>> findAll() async {
    final docs = await _collection.find().toList();
    return docs.map((doc) => Modul.fromJson(doc)).toList();
  }

  @override
  Future<Modul?> findById(String id) async {
    final doc = await _collection.findOne(where.eq('_id', id));
    return doc != null ? Modul.fromJson(doc) : null;
  }

  Future<Modul?> findByCode(String code) async {
    final doc = await _collection.findOne(where.eq('code', code));
    return doc != null ? Modul.fromJson(doc) : null;
  }

  @override
  Future<Modul> insert(Modul modul) async {
    await _collection.insertOne(modul.toJson());
    return modul;
  }

  @override
  Future<Modul> update(Modul modul) async {
    await _collection.replaceOne(
      where.eq('_id', modul.id),
      modul.toJson(),
    );
    return modul;
  }

  @override
  Future<void> delete(String id) async {
    await _collection.deleteOne(where.eq('_id', id));
  }

  Future<List<Modul>> findByCicleCodes(List<String> cicleCodes) async {
    final docs = await _collection
        .find(where.oneFrom('cicleCodes', cicleCodes))
        .toList();
    return docs.map((doc) => Modul.fromJson(doc)).toList();
  }
}
```

---

### GroupRepository

```dart
class GroupRepository implements Repository<Group> {
  final MongoDbDatasource _datasource;

  GroupRepository(this._datasource);

  DbCollection get _collection => _datasource.collection('groups');

  @override
  Future<List<Group>> findAll() async {
    final docs = await _collection.find().toList();
    return docs.map((doc) => Group.fromJson(doc)).toList();
  }

  @override
  Future<Group?> findById(String id) async {
    final doc = await _collection.findOne(where.eq('_id', id));
    return doc != null ? Group.fromJson(doc) : null;
  }

  @override
  Future<Group> insert(Group group) async {
    await _collection.insertOne(group.toJson());
    return group;
  }

  @override
  Future<Group> update(Group group) async {
    await _collection.replaceOne(
      where.eq('_id', group.id),
      group.toJson(),
    );
    return group;
  }

  @override
  Future<void> delete(String id) async {
    await _collection.deleteOne(where.eq('_id', id));
  }

  Future<List<Group>> findByAcademicYear(String academicYearId) async {
    final docs = await _collection
        .find(where.eq('academicYearId', academicYearId))
        .toList();
    return docs.map((doc) => Group.fromJson(doc)).toList();
  }
}
```

---

### DailyNoteRepository

```dart
class DailyNoteRepository implements Repository<DailyNote> {
  final MongoDbDatasource _datasource;

  DailyNoteRepository(this._datasource);

  DbCollection get _collection => _datasource.collection('daily_notes');

  @override
  Future<List<DailyNote>> findAll() async {
    final docs = await _collection.find().toList();
    return docs.map((doc) => DailyNote.fromJson(doc)).toList();
  }

  @override
  Future<DailyNote?> findById(String id) async {
    final doc = await _collection.findOne(where.eq('_id', id));
    return doc != null ? DailyNote.fromJson(doc) : null;
  }

  @override
  Future<DailyNote> insert(DailyNote note) async {
    await _collection.insertOne(note.toJson());
    return note;
  }

  @override
  Future<DailyNote> update(DailyNote note) async {
    await _collection.replaceOne(
      where.eq('_id', note.id),
      note.toJson(),
    );
    return note;
  }

  @override
  Future<void> delete(String id) async {
    await _collection.deleteOne(where.eq('_id', id));
  }

  Future<List<DailyNote>> findByGroupAndModule(String groupId, String modulId) async {
    final docs = await _collection
        .find(where.eq('groupId', groupId).eq('modulId', modulId))
        .toList();
    return docs.map((doc) => DailyNote.fromJson(doc)).toList();
  }

  Future<List<DailyNote>> findByRaId(String raId) async {
    final docs = await _collection
        .find(where.eq('raId', raId))
        .toList();
    return docs.map((doc) => DailyNote.fromJson(doc)).toList();
  }

  Future<DailyNote?> findByGroupRaDate(String groupId, String raId, DateTime date) async {
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();
    final doc = await _collection.findOne(
      where.eq('groupId', groupId).eq('raId', raId).eq('date', dateStr),
    );
    return doc != null ? DailyNote.fromJson(doc) : null;
  }
}
```

---

### AcademicYearRepository

```dart
class AcademicYearRepository implements Repository<AcademicYear> {
  final MongoDbDatasource _datasource;

  AcademicYearRepository(this._datasource);

  DbCollection get _collection => _datasource.collection('academic_years');

  @override
  Future<List<AcademicYear>> findAll() async {
    final docs = await _collection.find().toList();
    return docs.map((doc) => AcademicYear.fromJson(doc)).toList();
  }

  @override
  Future<AcademicYear?> findById(String id) async {
    final doc = await _collection.findOne(where.eq('_id', id));
    return doc != null ? AcademicYear.fromJson(doc) : null;
  }

  @override
  Future<AcademicYear> insert(AcademicYear year) async {
    await _collection.insertOne(year.toJson());
    return year;
  }

  @override
  Future<AcademicYear> update(AcademicYear year) async {
    await _collection.replaceOne(
      where.eq('_id', year.id),
      year.toJson(),
    );
    return year;
  }

  @override
  Future<void> delete(String id) async {
    await _collection.deleteOne(where.eq('_id', id));
  }

  Future<AcademicYear?> findActive() async {
    final doc = await _collection.findOne(where.eq('isActive', true));
    return doc != null ? AcademicYear.fromJson(doc) : null;
  }
}
```

---

### RecurringHolidayRepository

```dart
class RecurringHolidayRepository implements Repository<RecurringHoliday> {
  final MongoDbDatasource _datasource;

  RecurringHolidayRepository(this._datasource);

  DbCollection get _collection => _datasource.collection('recurring_holidays');

  @override
  Future<List<RecurringHoliday>> findAll() async {
    final docs = await _collection.find().toList();
    return docs.map((doc) => RecurringHoliday.fromJson(doc)).toList();
  }

  @override
  Future<RecurringHoliday?> findById(String id) async {
    final doc = await _collection.findOne(where.eq('_id', id));
    return doc != null ? RecurringHoliday.fromJson(doc) : null;
  }

  @override
  Future<RecurringHoliday> insert(RecurringHoliday holiday) async {
    await _collection.insertOne(holiday.toJson());
    return holiday;
  }

  @override
  Future<RecurringHoliday> update(RecurringHoliday holiday) async {
    await _collection.replaceOne(
      where.eq('_id', holiday.id),
      holiday.toJson(),
    );
    return holiday;
  }

  @override
  Future<void> delete(String id) async {
    await _collection.deleteOne(where.eq('_id', id));
  }

  Future<List<RecurringHoliday>> findEnabled() async {
    final docs = await _collection
        .find(where.eq('isEnabled', true))
        .toList();
    return docs.map((doc) => RecurringHoliday.fromJson(doc)).toList();
  }
}
```

---

## Part 4: Database Service

### High-level Service

```dart
import 'datasources/mongodb_datasource.dart';
import 'repositories/academic_year_repository.dart';
import 'repositories/group_repository.dart';
import 'repositories/modul_repository.dart';
import 'repositories/daily_note_repository.dart';
import 'repositories/recurring_holiday_repository.dart';

class DatabaseService {
  final MongoDbDatasource _datasource;

  late final AcademicYearRepository academicYearRepository;
  late final GroupRepository groupRepository;
  late final ModulRepository modulRepository;
  late final DailyNoteRepository dailyNoteRepository;
  late final RecurringHolidayRepository recurringHolidayRepository;

  DatabaseService(this._datasource) {
    academicYearRepository = AcademicYearRepository(_datasource);
    groupRepository = GroupRepository(_datasource);
    modulRepository = ModulRepository(_datasource);
    dailyNoteRepository = DailyNoteRepository(_datasource);
    recurringHolidayRepository = RecurringHolidayRepository(_datasource);
  }

  bool get isConnected => _datasource.isConnected;

  Future<void> connect() => _datasource.connect();
  Future<void> close() => _datasource.close();
}
```

---

## Part 5: State Integration

### Riverpod Providers

```dart
// lib/state/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/mongodb_datasource.dart';
import '../data/services/database_service.dart';

final mongoDbDatasourceProvider = Provider<MongoDbDatasource>((ref) {
  throw UnimplementedError('Override in main.dart');
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final datasource = ref.watch(mongoDbDatasourceProvider);
  return DatabaseService(datasource);
});
```

---

### main.dart Changes

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/datasources/mongodb_datasource.dart';
import 'state/providers.dart';
// ... other imports

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: 'lib/.env');

  // Initialize MongoDB connection
  final datasource = MongoDbDatasource();
  await datasource.connect();

  runApp(
    ProviderScope(
      overrides: [
        mongoDbDatasourceProvider.overrideWithValue(datasource),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

### AppStateNotifier Changes

```dart
class AppStateNotifier extends StateNotifier<AppState> {
  final DatabaseService _db;

  AppStateNotifier(this._db) : super(AppState.initial());

  Future<void> loadFromDatabase() async {
    final moduls = await _db.modulRepository.findAll();
    final groups = await _db.groupRepository.findAll();
    final dailyNotes = await _db.dailyNoteRepository.findAll();
    final recurringHolidays = await _db.recurringHolidayRepository.findAll();
    final currentYear = await _db.academicYearRepository.findActive();

    state = state.copyWith(
      moduls: moduls,
      groups: groups,
      dailyNotes: dailyNotes,
      recurringHolidays: recurringHolidays,
      currentYear: currentYear,
    );
  }

  // Update existing methods to persist changes
  Future<void> addModul(Modul modul) async {
    await _db.modulRepository.insert(modul);
    state = state.copyWith(moduls: [...state.moduls, modul]);
  }

  Future<void> updateModul(Modul modul) async {
    await _db.modulRepository.update(modul);
    state = state.copyWith(
      moduls: state.moduls.map((m) => m.id == modul.id ? modul : m).toList(),
    );
  }

  Future<void> deleteModul(String id) async {
    await _db.modulRepository.delete(id);
    state = state.copyWith(
      moduls: state.moduls.where((m) => m.id != id).toList(),
    );
  }

  // Similar pattern for groups, dailyNotes, etc.
}
```

---

## Part 6: Environment Configuration

### Create `lib/.env.example` (committed)

```bash
# MongoDB connection for Flutter app
# Copy to lib/.env and set your credentials
MONGO_URI=mongodb://cam_user:your_password@localhost:27017/class_activity_manager
```

### Create `lib/.env` (git-ignored)

Copy from example and set actual password from `docker/.env`.

---

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `pubspec.yaml` | Modify | Add mongo_dart, flutter_dotenv |
| `lib/.env.example` | Create | Template for app credentials |
| `lib/.env` | Create | Actual credentials (git-ignored) |
| `lib/models/criteri_avaluacio.dart` | Modify | Add toJson/fromJson |
| `lib/models/recurring_holiday.dart` | Modify | Add toJson/fromJson |
| `lib/models/vacation_period.dart` | Modify | Add toJson/fromJson |
| `lib/models/ra.dart` | Modify | Add toJson/fromJson |
| `lib/models/modul.dart` | Modify | Add toJson/fromJson |
| `lib/models/academic_year.dart` | Modify | Add toJson/fromJson |
| `lib/models/group.dart` | Modify | Add toJson/fromJson |
| `lib/models/daily_note.dart` | Modify | Add toJson/fromJson |
| `lib/data/datasources/mongodb_datasource.dart` | Create | Connection management |
| `lib/data/repositories/modul_repository.dart` | Create | Modul CRUD |
| `lib/data/repositories/group_repository.dart` | Create | Group CRUD |
| `lib/data/repositories/daily_note_repository.dart` | Create | DailyNote CRUD |
| `lib/data/repositories/academic_year_repository.dart` | Create | AcademicYear CRUD |
| `lib/data/repositories/recurring_holiday_repository.dart` | Create | RecurringHoliday CRUD |
| `lib/data/services/database_service.dart` | Create | High-level service |
| `lib/state/providers.dart` | Create | Riverpod providers |
| `lib/state/app_state.dart` | Modify | Add DB loading/saving |
| `lib/main.dart` | Modify | Initialize dotenv and DB connection |

---

## Verification Steps

1. `flutter pub get` - Install new dependencies
2. Create `lib/.env` from template with credentials from `docker/.env`
3. Ensure MongoDB is running: `./scripts/mongo-start.sh`
4. `flutter run -d linux` - Start app
5. Verify data loads from database (should see pre-populated holidays)
6. Create a new group → restart app → verify group persists
7. Create daily notes → restart app → verify notes persist

---

## Implementation Phases

**Phase 1: Foundation**
- Add packages to pubspec.yaml
- Create lib/.env.example and lib/.env
- Add serialization to leaf models (CriteriAvaluacio, RecurringHoliday, VacationPeriod)

**Phase 2: Complete Serialization**
- Add serialization to RA, Modul, AcademicYear
- Add serialization to Group, DailyNote

**Phase 3: Data Layer**
- Create MongoDbDatasource
- Create all repository classes
- Create DatabaseService

**Phase 4: State Integration**
- Create Riverpod providers
- Modify AppStateNotifier for persistence
- Update main.dart for initialization
- Test full integration

---

## Bug Fixes Applied During Implementation

### 1. Import Conflict: `Group` Class Name Collision

**Problem:** `mongo_dart` exports a `Group` class that conflicts with the app's `Group` model.

**Solution:** Use selective imports in `group_repository.dart`:

```dart
// WRONG - causes ambiguous import error
import 'package:mongo_dart/mongo_dart.dart';

// CORRECT - only import what's needed
import 'package:mongo_dart/mongo_dart.dart' show DbCollection, where;
```

---

### 2. Nullable DatabaseService for Offline Mode

**Problem:** App crashes if MongoDB is not available at startup.

**Solution:** Make `DatabaseService` nullable in providers:

```dart
// lib/state/providers.dart
final databaseServiceProvider = Provider<DatabaseService?>((ref) {
  return null;  // Default to null, override in main.dart when connected
});
```

---

### 3. AppStateNotifier with Optional Database

**Problem:** Methods fail when database is not connected.

**Solution:** Add `hasDatabase` guard and check before all DB operations:

```dart
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier(this._db) : super(AppState(recurringHolidays: _defaultRecurringHolidays()));

  final DatabaseService? _db;  // Nullable

  bool get hasDatabase => _db != null && _db.isConnected;

  Future<void> addGroup(Group group) async {
    if (hasDatabase) {
      await _db!.groupRepository.insert(group);
    }
    // Always update in-memory state
    state = state.copyWith(groups: [...state.groups, group]);
  }

  // Apply same pattern to ALL CRUD methods
}
```

---

### 4. Widget Initialization Timing Issue

**Problem:** Calling `ref.read()` in `initState` causes Flutter framework assertion error: `'!_dirty': is not true`.

**Solution:** Delay initialization until after the first frame using `addPostFrameCallback`:

```dart
class _AppWithDatabaseInitState extends ConsumerState<_AppWithDatabaseInit> {
  @override
  void initState() {
    super.initState();
    // WRONG - causes framework error
    // _initializeData();

    // CORRECT - wait for first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      await ref.read(appStateProvider.notifier).loadFromDatabase();
      if (mounted) {  // Check mounted before setState
        setState(() => _initialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialized = true;
          _error = e.toString();
        });
      }
    }
  }
}
```

---

### 5. Provider Override Pattern

**Problem:** Conditional provider overrides can cause issues with Riverpod's provider resolution.

**Solution:** Always override the provider, passing null when DB is not connected:

```dart
// main.dart
runApp(
  ProviderScope(
    overrides: [
      // WRONG - conditional override
      // if (databaseService != null)
      //   databaseServiceProvider.overrideWithValue(databaseService),

      // CORRECT - always override, value can be null
      databaseServiceProvider.overrideWithValue(databaseService),
    ],
    child: const _AppWithDatabaseInit(),
  ),
);
```

---

### 6. AppState with Loading/Initialized Flags

**Problem:** UI needs to know when data is loading and when initialization is complete.

**Solution:** Add state flags:

```dart
class AppState {
  AppState({
    // ... existing fields
    this.isLoading = false,
    this.isInitialized = false,
  });

  final bool isLoading;
  final bool isInitialized;

  AppState copyWith({
    // ... existing params
    bool? isLoading,
    bool? isInitialized,
  }) {
    return AppState(
      // ... existing assignments
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}
```

---

## Final Working Architecture

```
main.dart
    │
    ├── Load .env
    ├── Connect to MongoDB (optional, can fail)
    ├── Create DatabaseService? (null if connection failed)
    │
    └── ProviderScope
        ├── databaseServiceProvider.overrideWithValue(databaseService)
        │
        └── _AppWithDatabaseInit (ConsumerStatefulWidget)
            │
            ├── initState → addPostFrameCallback → _initializeData()
            │
            └── appStateProvider
                └── AppStateNotifier(DatabaseService?)
                    ├── hasDatabase check
                    ├── loadFromDatabase() (skips if no DB)
                    └── CRUD methods (persist if DB available)
```

**Behavior:**
- MongoDB running: Full persistence, data survives restarts
- MongoDB not running: In-memory only mode, app still functional
