import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audit/audit_logger.dart';
import '../core/utils/date_formats.dart';
import '../data/models/curriculum/curriculum.dart';
import '../data/repositories/caching_academic_year_repository.dart';
import '../data/repositories/caching_daily_note_repository.dart';
import '../data/repositories/caching_group_repository.dart';
import '../data/repositories/caching_modul_repository.dart';
import '../data/repositories/caching_recurring_holiday_repository.dart';
import '../data/services/cache_service.dart';
import '../data/services/database_service.dart';
import '../models/models.dart';
import 'providers.dart';

/// Sentinel value to distinguish "not provided" from explicit `null` in copyWith.
const _absent = _Absent();

class _Absent {
  const _Absent();
}

/// In-memory app state: academic year, holidays, groups, modules.
class AppState {
  AppState({
    this.currentYear,
    List<RecurringHoliday>? recurringHolidays,
    List<Group>? groups,
    List<Modul>? moduls,
    List<String>? selectedCicleIds,
    List<DailyNote>? dailyNotes,
    this.isLoading = false,
    this.isInitialized = false,
  }) : recurringHolidays = recurringHolidays ?? [],
       groups = groups ?? [],
       moduls = moduls ?? [],
       selectedCicleIds = selectedCicleIds ?? [],
       dailyNotes = dailyNotes ?? [];

  final AcademicYear? currentYear;
  final List<RecurringHoliday> recurringHolidays;
  final List<Group> groups;
  final List<Modul> moduls;
  final List<String> selectedCicleIds;
  final List<DailyNote> dailyNotes;
  final bool isLoading;
  final bool isInitialized;

  AppState copyWith({
    Object? currentYear = _absent,
    List<RecurringHoliday>? recurringHolidays,
    List<Group>? groups,
    List<Modul>? moduls,
    List<String>? selectedCicleIds,
    List<DailyNote>? dailyNotes,
    bool? isLoading,
    bool? isInitialized,
  }) {
    return AppState(
      currentYear: currentYear == _absent
          ? this.currentYear
          : currentYear as AcademicYear?,
      recurringHolidays: recurringHolidays ?? this.recurringHolidays,
      groups: groups ?? this.groups,
      moduls: moduls ?? this.moduls,
      selectedCicleIds: selectedCicleIds ?? this.selectedCicleIds,
      dailyNotes: dailyNotes ?? this.dailyNotes,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Notifier that holds and updates [AppState] with local-first caching.
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier(this._db, this._cacheService, [AuditLogger? logger])
    : _audit = logger,
      super(AppState(recurringHolidays: _defaultRecurringHolidays()));

  final DatabaseService? _db;
  final CacheService _cacheService;
  final AuditLogger? _audit;

  // Caching repositories
  late final CachingModulRepository _modulRepo;
  late final CachingGroupRepository _groupRepo;
  late final CachingDailyNoteRepository _dailyNoteRepo;
  late final CachingAcademicYearRepository _academicYearRepo;
  late final CachingRecurringHolidayRepository _recurringHolidayRepo;

  bool _reposInitialized = false;

  void _ensureRepos() {
    if (_reposInitialized) return;
    final local = _cacheService.local;
    final queue = _cacheService.queue;
    _modulRepo = CachingModulRepository(local, queue);
    _groupRepo = CachingGroupRepository(local, queue);
    _dailyNoteRepo = CachingDailyNoteRepository(local, queue);
    _academicYearRepo = CachingAcademicYearRepository(local, queue);
    _recurringHolidayRepo = CachingRecurringHolidayRepository(local, queue);
    _reposInitialized = true;
  }

  DatabaseService? get _connectedDb {
    final db = _db;
    if (db == null || !db.isConnected) return null;
    return db;
  }

  bool get hasDatabase => _connectedDb != null;

  /// Load all data from database on startup.
  /// Uses remote MongoDB if connected, otherwise local cache.
  Future<void> loadFromDatabase() async {
    final traceId = sharedUuid.v4();
    _audit?.log('AppState.loadFromDatabase', 'started', {}, traceId: traceId);
    _ensureRepos();
    state = state.copyWith(isLoading: true);

    try {
      final db = _connectedDb;

      if (db != null) {
        _audit?.log('AppState.loadFromDatabase', 'action', {
          'step': 'pullFromRemote',
        }, traceId: traceId);
        await _pullFromRemote(db);
      } else {
        _audit?.log('AppState.loadFromDatabase', 'action', {
          'step': 'loadFromLocalCache',
        }, traceId: traceId);
        await _loadFromLocalCache();
      }

      state = state.copyWith(isLoading: false, isInitialized: true);

      // If holidays were empty, persist the defaults
      if (state.recurringHolidays.isNotEmpty &&
          (await _recurringHolidayRepo.findAll()).isEmpty) {
        _audit?.log('AppState.loadFromDatabase', 'action', {
          'step': 'persistDefaultHolidays',
        }, traceId: traceId);
        for (final holiday in state.recurringHolidays) {
          await _recurringHolidayRepo.insert(holiday);
        }
      }

      _audit?.log('AppState.loadFromDatabase', 'action', {
        'step': 'triggerSync',
      }, traceId: traceId);
      await _cacheService.triggerSync();
      _audit?.log('AppState.loadFromDatabase', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('AppState.loadFromDatabase', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      // On error, fall back to local cache or defaults
      try {
        await _loadFromLocalCache();
      } catch (cacheError) {
        // If local cache also fails, log and use defaults
        _audit?.log('AppState.loadFromDatabase', 'failed', {
          'step': 'localCacheFallback',
          'error': cacheError.toString(),
        }, traceId: traceId);
        state = state.copyWith(recurringHolidays: _defaultRecurringHolidays());
      }
      state = state.copyWith(isLoading: false, isInitialized: true);
      rethrow;
    }
  }

  Future<void> _pullFromRemote(DatabaseService db) async {
    final moduls = await db.modulRepository.findAll();
    final groups = await db.groupRepository.findAll();
    final dailyNotes = await db.dailyNoteRepository.findAll();
    final recurringHolidays = await db.recurringHolidayRepository.findAll();
    final currentYear = await db.academicYearRepository.findActive();
    final allYears = await db.academicYearRepository.findAll();

    // Update local cache
    await _modulRepo.syncFromRemote(moduls);
    await _groupRepo.syncFromRemote(groups);
    await _dailyNoteRepo.syncFromRemote(dailyNotes);
    await _recurringHolidayRepo.syncFromRemote(recurringHolidays);
    await _academicYearRepo.syncFromRemote(allYears);

    state = state.copyWith(
      moduls: moduls,
      groups: groups,
      dailyNotes: dailyNotes,
      recurringHolidays: recurringHolidays.isEmpty
          ? _defaultRecurringHolidays()
          : recurringHolidays,
      currentYear: currentYear,
    );
  }

  Future<void> _loadFromLocalCache() async {
    final moduls = await _modulRepo.findAll();
    final groups = await _groupRepo.findAll();
    final dailyNotes = await _dailyNoteRepo.findAll();
    final recurringHolidays = await _recurringHolidayRepo.findAll();
    final currentYear = await _academicYearRepo.findActive();

    state = state.copyWith(
      moduls: moduls,
      groups: groups,
      dailyNotes: dailyNotes,
      recurringHolidays: recurringHolidays.isEmpty
          ? _defaultRecurringHolidays()
          : recurringHolidays,
      currentYear: currentYear,
    );
  }

  static List<RecurringHoliday> _defaultRecurringHolidays() {
    // (month, day, name) - PRD defaults for Catalunya
    const defaults = [
      (1, 1, 'Cap d\'Any'),
      (1, 6, 'Reis'),
      (5, 1, 'Dia del Treball'),
      (6, 24, 'Sant Joan'),
      (8, 15, 'L\'Assumpció'),
      (9, 11, 'Diada Nacional de Catalunya'),
      (10, 12, 'Festa Nacional d\'Espanya'),
      (11, 1, 'Tots Sants'),
      (12, 6, 'Dia de la Constitució'),
      (12, 8, 'La Immaculada'),
      (12, 25, 'Nadal'),
      (12, 26, 'Sant Esteve'),
    ];
    return defaults
        .map(
          (e) => RecurringHoliday(
            id: sharedUuid.v4(),
            name: e.$3,
            month: e.$1,
            day: e.$2,
            isEnabled: true,
          ),
        )
        .toList();
  }

  // Academic year
  Future<void> setCurrentYear(AcademicYear year) async {
    final traceId = sharedUuid.v4();
    _audit?.log('AcademicYear.set', 'started', {
      'yearId': year.id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      await _academicYearRepo.insert(year);
      await _academicYearRepo.setActiveYear(year.id);
      await _cacheService.triggerSync();
      state = state.copyWith(currentYear: year);
      _audit?.log('AcademicYear.set', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('AcademicYear.set', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> updateCurrentYear(AcademicYear year) async {
    final traceId = sharedUuid.v4();
    _audit?.log('AcademicYear.update', 'started', {
      'yearId': year.id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      await _academicYearRepo.update(year);
      await _cacheService.triggerSync();
      state = state.copyWith(currentYear: year);
      _audit?.log('AcademicYear.update', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('AcademicYear.update', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> clearCurrentYear() async {
    final traceId = sharedUuid.v4();
    _audit?.log('AcademicYear.clear', 'started', {}, traceId: traceId);
    try {
      _ensureRepos();
      final currentYear = state.currentYear;
      if (currentYear != null) {
        final year = currentYear.copyWith(isActive: false);
        await _academicYearRepo.update(year);
        await _cacheService.triggerSync();
      }
      state = state.copyWith(currentYear: null);
      _audit?.log('AcademicYear.clear', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('AcademicYear.clear', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  // Vacation periods (on current year)
  Future<void> addVacationPeriod(VacationPeriod period) async {
    final traceId = sharedUuid.v4();
    _audit?.log('VacationPeriod.add', 'started', {
      'periodId': period.id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      final year = state.currentYear;
      if (year == null) {
        _audit?.log('VacationPeriod.add', 'completed', {
          'result': 'noop',
        }, traceId: traceId);
        return;
      }
      final updated = List<VacationPeriod>.from(year.vacationPeriods)
        ..add(period);
      final newYear = year.copyWith(vacationPeriods: updated);
      await _academicYearRepo.update(newYear);
      await _cacheService.triggerSync();
      state = state.copyWith(currentYear: newYear);
      _audit?.log('VacationPeriod.add', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('VacationPeriod.add', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> updateVacationPeriod(VacationPeriod period) async {
    final traceId = sharedUuid.v4();
    _audit?.log('VacationPeriod.update', 'started', {
      'periodId': period.id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      final year = state.currentYear;
      if (year == null) {
        _audit?.log('VacationPeriod.update', 'completed', {
          'result': 'noop',
        }, traceId: traceId);
        return;
      }
      final updated = year.vacationPeriods
          .map((p) => p.id == period.id ? period : p)
          .toList();
      final newYear = year.copyWith(vacationPeriods: updated);
      await _academicYearRepo.update(newYear);
      await _cacheService.triggerSync();
      state = state.copyWith(currentYear: newYear);
      _audit?.log('VacationPeriod.update', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('VacationPeriod.update', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> removeVacationPeriod(String id) async {
    final traceId = sharedUuid.v4();
    _audit?.log('VacationPeriod.remove', 'started', {
      'periodId': id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      final year = state.currentYear;
      if (year == null) {
        _audit?.log('VacationPeriod.remove', 'completed', {
          'result': 'noop',
        }, traceId: traceId);
        return;
      }
      final updated = year.vacationPeriods.where((p) => p.id != id).toList();
      final newYear = year.copyWith(vacationPeriods: updated);
      await _academicYearRepo.update(newYear);
      await _cacheService.triggerSync();
      state = state.copyWith(currentYear: newYear);
      _audit?.log('VacationPeriod.remove', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('VacationPeriod.remove', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  // Recurring holidays
  Future<void> addRecurringHoliday(RecurringHoliday holiday) async {
    final traceId = sharedUuid.v4();
    _audit?.log('RecurringHoliday.add', 'started', {
      'holidayId': holiday.id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      await _recurringHolidayRepo.insert(holiday);
      await _cacheService.triggerSync();
      state = state.copyWith(
        recurringHolidays: [...state.recurringHolidays, holiday],
      );
      _audit?.log('RecurringHoliday.add', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('RecurringHoliday.add', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> updateRecurringHoliday(RecurringHoliday holiday) async {
    final traceId = sharedUuid.v4();
    _audit?.log('RecurringHoliday.update', 'started', {
      'holidayId': holiday.id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      await _recurringHolidayRepo.update(holiday);
      await _cacheService.triggerSync();
      state = state.copyWith(
        recurringHolidays: state.recurringHolidays
            .map((h) => h.id == holiday.id ? holiday : h)
            .toList(),
      );
      _audit?.log('RecurringHoliday.update', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('RecurringHoliday.update', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> removeRecurringHoliday(String id) async {
    final traceId = sharedUuid.v4();
    _audit?.log('RecurringHoliday.remove', 'started', {
      'holidayId': id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      await _recurringHolidayRepo.delete(id);
      await _cacheService.triggerSync();
      state = state.copyWith(
        recurringHolidays: state.recurringHolidays
            .where((h) => h.id != id)
            .toList(),
      );
      _audit?.log('RecurringHoliday.remove', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('RecurringHoliday.remove', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  // Groups
  Future<void> addGroup(Group group) async {
    final traceId = sharedUuid.v4();
    _audit?.log('Group.add', 'started', {
      'groupId': group.id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      await _groupRepo.insert(group);
      await _cacheService.triggerSync();
      state = state.copyWith(groups: [...state.groups, group]);
      _audit?.log('Group.add', 'completed', {'result': 'ok'}, traceId: traceId);
    } catch (e) {
      _audit?.log('Group.add', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> updateGroup(Group group) async {
    final traceId = sharedUuid.v4();
    _audit?.log('Group.update', 'started', {
      'groupId': group.id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      await _groupRepo.update(group);
      await _cacheService.triggerSync();
      state = state.copyWith(
        groups: state.groups.map((g) => g.id == group.id ? group : g).toList(),
      );
      _audit?.log('Group.update', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('Group.update', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> removeGroup(String id) async {
    final traceId = sharedUuid.v4();
    _audit?.log('Group.remove', 'started', {'groupId': id}, traceId: traceId);
    try {
      _ensureRepos();
      await _groupRepo.delete(id);
      await _cacheService.triggerSync();
      state = state.copyWith(
        groups: state.groups.where((g) => g.id != id).toList(),
      );
      _audit?.log('Group.remove', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('Group.remove', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  // Moduls
  Future<void> addModul(Modul modul) async {
    final traceId = sharedUuid.v4();
    _audit?.log('Modul.add', 'started', {
      'modulId': modul.id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      await _modulRepo.insert(modul);
      await _cacheService.triggerSync();
      state = state.copyWith(moduls: [...state.moduls, modul]);
      _audit?.log('Modul.add', 'completed', {'result': 'ok'}, traceId: traceId);
    } catch (e) {
      _audit?.log('Modul.add', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> updateModul(Modul modul) async {
    final traceId = sharedUuid.v4();
    _audit?.log('Modul.update', 'started', {
      'modulId': modul.id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      await _modulRepo.update(modul);
      await _cacheService.triggerSync();
      state = state.copyWith(
        moduls: state.moduls.map((m) => m.id == modul.id ? modul : m).toList(),
      );
      _audit?.log('Modul.update', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('Modul.update', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> removeModul(String id) async {
    final traceId = sharedUuid.v4();
    _audit?.log('Modul.remove', 'started', {'modulId': id}, traceId: traceId);
    try {
      _ensureRepos();
      await _modulRepo.delete(id);
      await _cacheService.triggerSync();
      state = state.copyWith(
        moduls: state.moduls.where((m) => m.id != id).toList(),
      );
      _audit?.log('Modul.remove', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('Modul.remove', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  void setSelectedCicles(List<String> cicleCodes) {
    state = state.copyWith(selectedCicleIds: cicleCodes);
  }

  /// Import a module from curriculum YAML: creates Modul and RAs from UFs.
  /// If the module already exists (by code), accumulates the cicleCode.
  Future<void> importModulFromCurriculum(
    String cicleCode,
    CurriculumModul cm,
  ) async {
    final traceId = sharedUuid.v4();
    _audit?.log('Modul.importFromCurriculum', 'started', {
      'cicleCode': cicleCode,
      'modulCode': cm.codi,
    }, traceId: traceId);
    try {
      _ensureRepos();
      final existing = state.moduls.where((m) => m.code == cm.codi).toList();
      if (existing.isNotEmpty) {
        final modul = existing.first;
        if (!modul.cicleCodes.contains(cicleCode)) {
          await updateModul(
            modul.copyWith(cicleCodes: [...modul.cicleCodes, cicleCode]),
          );
        }
        _audit?.log('Modul.importFromCurriculum', 'completed', {
          'result': 'updated',
        }, traceId: traceId);
        return;
      }
      final ras = <RA>[];
      for (var i = 0; i < cm.ufs.length; i++) {
        final uf = cm.ufs[i];
        ras.add(
          RA(
            id: nextId(),
            number: i + 1,
            code: uf.codi,
            title: uf.nom,
            durationHours: uf.hores,
            order: i,
          ),
        );
      }
      final modul = Modul(
        id: nextId(),
        code: cm.codi,
        name: cm.nom,
        totalHours: cm.hores,
        ras: ras,
        cicleCodes: [cicleCode],
      );
      await addModul(modul);
      _audit?.log('Modul.importFromCurriculum', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('Modul.importFromCurriculum', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  /// Add or update RA in a module.
  Future<void> setModulRA(String modulId, RA ra) async {
    final traceId = sharedUuid.v4();
    _audit?.log('Modul.setRA', 'started', {
      'modulId': modulId,
      'raId': ra.id,
    }, traceId: traceId);
    try {
      _ensureRepos();
      final list = state.moduls.where((m) => m.id == modulId).toList();
      if (list.isEmpty) {
        _audit?.log('Modul.setRA', 'completed', {
          'result': 'noop',
        }, traceId: traceId);
        return;
      }
      final modul = list.first;
      final existing = modul.ras.where((r) => r.id == ra.id).toList();
      final ras = existing.isEmpty
          ? [...modul.ras, ra]
          : modul.ras.map((r) => r.id == ra.id ? ra : r).toList();
      await updateModul(modul.copyWith(ras: ras));
      _audit?.log('Modul.setRA', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('Modul.setRA', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> removeModulRA(String modulId, String raId) async {
    final traceId = sharedUuid.v4();
    _audit?.log('Modul.removeRA', 'started', {
      'modulId': modulId,
      'raId': raId,
    }, traceId: traceId);
    try {
      _ensureRepos();
      final list = state.moduls.where((m) => m.id == modulId).toList();
      if (list.isEmpty) {
        _audit?.log('Modul.removeRA', 'completed', {
          'result': 'noop',
        }, traceId: traceId);
        return;
      }
      final modul = list.first;
      final ras = modul.ras.where((r) => r.id != raId).toList();
      await updateModul(modul.copyWith(ras: ras));
      _audit?.log('Modul.removeRA', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('Modul.removeRA', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> setDailyNote(DailyNote note) async {
    final traceId = sharedUuid.v4();
    _audit?.log('DailyNote.save', 'started', {
      'groupId': note.groupId,
      'raId': note.raId,
      'date': note.date.toIso8601String(),
    }, traceId: traceId);
    try {
      _ensureRepos();
      final notes = state.dailyNotes
          .where((n) => !_isSameDailyNote(n, note))
          .toList();

      if (_isDailyNoteEmpty(note) && !note.completed) {
        final existing = state.dailyNotes
            .where((n) => _isSameDailyNote(n, note))
            .toList();
        if (existing.isNotEmpty) {
          _audit?.log('DailyNote.save', 'action', {
            'step': 'delete',
          }, traceId: traceId);
          await _dailyNoteRepo.delete(existing.first.id);
          _audit?.log('DailyNote.save', 'action', {
            'step': 'triggerSync',
          }, traceId: traceId);
          await _cacheService.triggerSync();
        }
        state = state.copyWith(dailyNotes: notes);
        _audit?.log('DailyNote.save', 'completed', {
          'result': 'deleted',
        }, traceId: traceId);
        return;
      }

      _audit?.log('DailyNote.save', 'action', {
        'step': 'findByGroupRaDate',
      }, traceId: traceId);
      final existingNote = await _dailyNoteRepo.findByGroupRaDate(
        note.groupId,
        note.raId,
        note.date,
      );

      if (existingNote != null) {
        final updatedNote = note.copyWith(id: existingNote.id);
        _audit?.log('DailyNote.save', 'action', {
          'step': 'update',
        }, traceId: traceId);
        await _dailyNoteRepo.update(updatedNote);
        _audit?.log('DailyNote.save', 'action', {
          'step': 'triggerSync',
        }, traceId: traceId);
        unawaited(_cacheService.triggerSync()); // Fire-and-forget, don't block UI
        state = state.copyWith(dailyNotes: [...notes, updatedNote]);
      } else {
        _audit?.log('DailyNote.save', 'action', {
          'step': 'insert',
        }, traceId: traceId);
        await _dailyNoteRepo.insert(note);
        _audit?.log('DailyNote.save', 'action', {
          'step': 'triggerSync',
        }, traceId: traceId);
        unawaited(_cacheService.triggerSync()); // Fire-and-forget, don't block UI
        state = state.copyWith(dailyNotes: [...notes, note]);
      }
      _audit?.log('DailyNote.save', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('DailyNote.save', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  DailyNote? getDailyNote(String groupId, String raId, DateTime date) {
    final list = state.dailyNotes
        .where(
          (n) =>
              n.groupId == groupId &&
              n.raId == raId &&
              _isSameDay(n.date, date),
        )
        .toList();
    return list.isEmpty ? null : list.first;
  }

  List<DailyNote> getDailyNotesForRa(String raId) {
    return state.dailyNotes.where((n) => n.raId == raId).toList();
  }

  List<DailyNote> getDailyNotesForGroupRa(String groupId, String raId) {
    return state.dailyNotes
        .where((n) => n.groupId == groupId && n.raId == raId)
        .toList();
  }

  // Group-Module relationship methods
  Future<void> addModuleToGroup(String groupId, String modulId) async {
    final traceId = sharedUuid.v4();
    _audit?.log('Group.addModule', 'started', {
      'groupId': groupId,
      'modulId': modulId,
    }, traceId: traceId);
    try {
      _ensureRepos();
      final list = state.groups.where((g) => g.id == groupId).toList();
      if (list.isEmpty) {
        _audit?.log('Group.addModule', 'completed', {
          'result': 'noop',
        }, traceId: traceId);
        return;
      }
      final group = list.first;
      if (group.moduleIds.contains(modulId)) {
        _audit?.log('Group.addModule', 'completed', {
          'result': 'noop',
        }, traceId: traceId);
        return;
      }
      await updateGroup(
        group.copyWith(moduleIds: [...group.moduleIds, modulId]),
      );
      _audit?.log('Group.addModule', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('Group.addModule', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  Future<void> removeModuleFromGroup(String groupId, String modulId) async {
    final traceId = sharedUuid.v4();
    _audit?.log('Group.removeModule', 'started', {
      'groupId': groupId,
      'modulId': modulId,
    }, traceId: traceId);
    try {
      _ensureRepos();
      final list = state.groups.where((g) => g.id == groupId).toList();
      if (list.isEmpty) {
        _audit?.log('Group.removeModule', 'completed', {
          'result': 'noop',
        }, traceId: traceId);
        return;
      }
      final group = list.first;
      await updateGroup(
        group.copyWith(
          moduleIds: group.moduleIds.where((id) => id != modulId).toList(),
        ),
      );
      _audit?.log('Group.removeModule', 'completed', {
        'result': 'ok',
      }, traceId: traceId);
    } catch (e) {
      _audit?.log('Group.removeModule', 'failed', {
        'error': e.toString(),
      }, traceId: traceId);
      rethrow;
    }
  }

  List<Group> getGroupsForModule(String modulId) {
    return state.groups.where((g) => g.moduleIds.contains(modulId)).toList();
  }

  String nextId() => sharedUuid.v4();

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isSameDailyNote(DailyNote a, DailyNote b) {
    return a.id == b.id ||
        (a.raId == b.raId &&
            a.groupId == b.groupId &&
            _isSameDay(a.date, b.date));
  }

  static bool _isDailyNoteEmpty(DailyNote note) {
    return (note.plannedContent == null ||
            note.plannedContent!.trim().isEmpty) &&
        (note.actualContent == null || note.actualContent!.trim().isEmpty) &&
        (note.notes == null || note.notes!.trim().isEmpty);
  }
}

/// Provider for app state with database persistence.
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((
  ref,
) {
  final db = ref.watch(databaseServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return AppStateNotifier(db, cacheService, null);
});
