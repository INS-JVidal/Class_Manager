import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:class_activity_manager/data/cache/schemas/schemas.dart';
import 'package:class_activity_manager/data/cache/sync_queue.dart';
import 'package:class_activity_manager/data/datasources/local_datasource.dart';
import 'package:class_activity_manager/data/datasources/mongodb_datasource.dart';
import 'package:class_activity_manager/data/services/cache_service.dart';
import 'package:class_activity_manager/models/models.dart';
import 'package:class_activity_manager/state/app_state.dart';

import 'helpers/test_audit_logger.dart';

/// Test-friendly CacheService that uses in-memory Isar.
class TestCacheService extends CacheService {
  TestCacheService(super.local, super.remote, super.queue);

  @override
  Future<void> triggerSync() async {
    // No-op for tests
  }
}

/// Test-friendly LocalDatasource with in-memory Isar.
class TestLocalDatasource extends LocalDatasource {
  Isar? _testIsar;

  @override
  bool get isInitialized => _testIsar != null;

  @override
  Isar get db {
    final isar = _testIsar;
    if (isar == null) {
      throw StateError('TestLocalDatasource not initialized');
    }
    return isar;
  }

  @override
  Future<void> initialize() async {
    if (_testIsar != null) return;

    await Isar.initializeIsarCore(download: true);
    _testIsar = await Isar.open([
      ModulCacheSchema,
      GroupCacheSchema,
      DailyNoteCacheSchema,
      AcademicYearCacheSchema,
      RecurringHolidayCacheSchema,
      SyncOperationSchema,
    ], directory: '');
  }

  @override
  Future<void> close() async {
    await _testIsar?.close();
    _testIsar = null;
  }
}

void main() {
  late TestLocalDatasource localDatasource;
  late MongoDbDatasource mongoDatasource;
  late SyncQueue syncQueue;
  late TestCacheService cacheService;

  setUpAll(() async {
    localDatasource = TestLocalDatasource();
    await localDatasource.initialize();
    mongoDatasource = MongoDbDatasource();
    syncQueue = SyncQueue(localDatasource);
    cacheService = TestCacheService(
      localDatasource,
      mongoDatasource,
      syncQueue,
    );
  });

  tearDownAll(() async {
    await localDatasource.close();
  });

  setUp(() async {
    // Clear all data between tests
    await localDatasource.db.writeTxn(() async {
      await localDatasource.db.clear();
    });
  });

  test('default recurring holidays are seeded', () {
    final notifier = AppStateNotifier(null, cacheService);

    final holidays = notifier.state.recurringHolidays;
    expect(holidays, hasLength(12));
    expect(holidays.every((h) => h.isEnabled), isTrue);
    expect(holidays.any((h) => h.name == 'Nadal'), isTrue);
  });

  test('group-module relationships can be managed', () async {
    final notifier = AppStateNotifier(null, cacheService);
    final group = Group(id: 'g1', name: 'DAW1-A');
    final modul = Modul(
      id: 'm1',
      code: 'MP01',
      name: 'Programació',
      totalHours: 120,
    );

    await notifier.addGroup(group);
    await notifier.addModul(modul);
    await notifier.addModuleToGroup(group.id, modul.id);

    final updatedGroup = notifier.state.groups.firstWhere(
      (g) => g.id == group.id,
    );
    expect(updatedGroup.moduleIds, contains(modul.id));

    await notifier.removeModuleFromGroup(group.id, modul.id);
    final removedGroup = notifier.state.groups.firstWhere(
      (g) => g.id == group.id,
    );
    expect(removedGroup.moduleIds, isNot(contains(modul.id)));
  });

  test('setModulRA adds and updates RAs', () async {
    final notifier = AppStateNotifier(null, cacheService);
    final modul = Modul(
      id: 'm1',
      code: 'MP02',
      name: 'Bases de dades',
      totalHours: 100,
    );
    await notifier.addModul(modul);

    final ra = RA(
      id: 'ra1',
      number: 1,
      code: 'RA1',
      title: 'Models relacionals',
      durationHours: 20,
      order: 0,
    );
    await notifier.setModulRA(modul.id, ra);

    final withRa = notifier.state.moduls.firstWhere((m) => m.id == modul.id);
    expect(withRa.ras, hasLength(1));
    expect(withRa.ras.first.title, 'Models relacionals');

    final updatedRa = ra.copyWith(title: 'Models i consultes SQL');
    await notifier.setModulRA(modul.id, updatedRa);

    final updated = notifier.state.moduls.firstWhere((m) => m.id == modul.id);
    expect(updated.ras, hasLength(1));
    expect(updated.ras.first.title, 'Models i consultes SQL');
  });

  test('setDailyNote adds, updates, and removes empty notes', () async {
    final notifier = AppStateNotifier(null, cacheService);
    final date = DateTime(2026, 1, 10);
    final note = DailyNote(
      id: 'n1',
      raId: 'ra1',
      modulId: 'm1',
      groupId: 'g1',
      date: date,
      plannedContent: 'Intro',
    );

    await notifier.setDailyNote(note);
    expect(notifier.state.dailyNotes, hasLength(1));

    final updatedNote = note.copyWith(actualContent: 'Intro + exemples');
    await notifier.setDailyNote(updatedNote);
    expect(notifier.state.dailyNotes, hasLength(1));
    expect(notifier.state.dailyNotes.first.actualContent, 'Intro + exemples');

    final emptyNote = DailyNote(
      id: 'n2',
      raId: 'ra1',
      modulId: 'm1',
      groupId: 'g1',
      date: date,
    );
    await notifier.setDailyNote(emptyNote);
    expect(notifier.state.dailyNotes, isEmpty);
  });

  test('setDailyNote emits audit events for happy path', () async {
    final auditLogger = TestAuditLogger();
    final notifier = AppStateNotifier(null, cacheService, auditLogger);
    final date = DateTime(2026, 1, 15);
    final note = DailyNote(
      id: 'n1',
      raId: 'ra1',
      modulId: 'm1',
      groupId: 'g1',
      date: date,
      plannedContent: 'Plan',
    );

    await notifier.setDailyNote(note);

    final dailyNoteEvents = auditLogger.events
        .where((e) => e.operation == 'DailyNote.save')
        .toList();
    expect(
      dailyNoteEvents.any((e) => e.phase == 'started'),
      isTrue,
      reason: 'expected DailyNote.save started',
    );
    expect(
      dailyNoteEvents.any((e) => e.phase == 'completed'),
      isTrue,
      reason: 'expected DailyNote.save completed',
    );
    expect(
      dailyNoteEvents.every((e) => e.phase != 'failed'),
      isTrue,
      reason: 'expected no DailyNote.save failed',
    );
  });

  test('loadFromDatabase emits audit events', () async {
    final auditLogger = TestAuditLogger();
    final notifier = AppStateNotifier(null, cacheService, auditLogger);

    await notifier.loadFromDatabase();

    final loadEvents = auditLogger.events
        .where((e) => e.operation == 'AppState.loadFromDatabase')
        .toList();
    expect(
      loadEvents.any((e) => e.phase == 'started'),
      isTrue,
      reason: 'expected loadFromDatabase started',
    );
    expect(
      loadEvents.any((e) => e.phase == 'action'),
      isTrue,
      reason: 'expected at least one action step',
    );
    expect(
      loadEvents.any((e) => e.phase == 'completed') ||
          loadEvents.any((e) => e.phase == 'failed'),
      isTrue,
      reason: 'expected completed or failed',
    );
  });
}
