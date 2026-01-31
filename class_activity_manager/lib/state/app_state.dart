import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/curriculum/curriculum.dart';
import '../data/services/database_service.dart';
import '../models/models.dart';
import 'providers.dart';

const _uuid = Uuid();

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
  })  : recurringHolidays = recurringHolidays ?? [],
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
    AcademicYear? currentYear,
    List<RecurringHoliday>? recurringHolidays,
    List<Group>? groups,
    List<Modul>? moduls,
    List<String>? selectedCicleIds,
    List<DailyNote>? dailyNotes,
    bool? isLoading,
    bool? isInitialized,
  }) {
    return AppState(
      currentYear: currentYear ?? this.currentYear,
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

/// Notifier that holds and updates [AppState] with MongoDB persistence.
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier(this._db) : super(AppState(recurringHolidays: _defaultRecurringHolidays()));

  final DatabaseService? _db;

  bool get hasDatabase => _db != null && _db.isConnected;

  /// Load all data from database on startup.
  Future<void> loadFromDatabase() async {
    if (!hasDatabase) {
      state = state.copyWith(isInitialized: true);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final moduls = await _db!.modulRepository.findAll();
      final groups = await _db!.groupRepository.findAll();
      final dailyNotes = await _db!.dailyNoteRepository.findAll();
      final recurringHolidays = await _db!.recurringHolidayRepository.findAll();
      final currentYear = await _db!.academicYearRepository.findActive();

      state = state.copyWith(
        moduls: moduls,
        groups: groups,
        dailyNotes: dailyNotes,
        recurringHolidays: recurringHolidays.isEmpty
            ? _defaultRecurringHolidays()
            : recurringHolidays,
        currentYear: currentYear,
        isLoading: false,
        isInitialized: true,
      );

      // If holidays were empty, persist the defaults
      if (recurringHolidays.isEmpty) {
        for (final holiday in state.recurringHolidays) {
          await _db!.recurringHolidayRepository.insert(holiday);
        }
      }
    } catch (e) {
      // On error, fall back to empty state with default holidays
      state = state.copyWith(
        recurringHolidays: _defaultRecurringHolidays(),
        isLoading: false,
        isInitialized: true,
      );
      rethrow;
    }
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
        .map((e) => RecurringHoliday(
              id: _uuid.v4(),
              name: e.$3,
              month: e.$1,
              day: e.$2,
              isEnabled: true,
            ))
        .toList();
  }

  // Academic year
  Future<void> setCurrentYear(AcademicYear year) async {
    if (hasDatabase) {
      await _db!.academicYearRepository.insert(year);
      await _db!.academicYearRepository.setActiveYear(year.id);
    }
    state = state.copyWith(currentYear: year);
  }

  Future<void> updateCurrentYear(AcademicYear year) async {
    if (hasDatabase) {
      await _db!.academicYearRepository.update(year);
    }
    state = state.copyWith(currentYear: year);
  }

  Future<void> clearCurrentYear() async {
    if (state.currentYear != null && hasDatabase) {
      final year = state.currentYear!.copyWith(isActive: false);
      await _db!.academicYearRepository.update(year);
    }
    state = state.copyWith(currentYear: null);
  }

  // Vacation periods (on current year)
  Future<void> addVacationPeriod(VacationPeriod period) async {
    final year = state.currentYear;
    if (year == null) return;
    final updated = List<VacationPeriod>.from(year.vacationPeriods)..add(period);
    final newYear = year.copyWith(vacationPeriods: updated);
    if (hasDatabase) {
      await _db!.academicYearRepository.update(newYear);
    }
    state = state.copyWith(currentYear: newYear);
  }

  Future<void> updateVacationPeriod(VacationPeriod period) async {
    final year = state.currentYear;
    if (year == null) return;
    final updated = year.vacationPeriods
        .map((p) => p.id == period.id ? period : p)
        .toList();
    final newYear = year.copyWith(vacationPeriods: updated);
    if (hasDatabase) {
      await _db!.academicYearRepository.update(newYear);
    }
    state = state.copyWith(currentYear: newYear);
  }

  Future<void> removeVacationPeriod(String id) async {
    final year = state.currentYear;
    if (year == null) return;
    final updated = year.vacationPeriods.where((p) => p.id != id).toList();
    final newYear = year.copyWith(vacationPeriods: updated);
    if (hasDatabase) {
      await _db!.academicYearRepository.update(newYear);
    }
    state = state.copyWith(currentYear: newYear);
  }

  // Recurring holidays
  Future<void> addRecurringHoliday(RecurringHoliday holiday) async {
    if (hasDatabase) {
      await _db!.recurringHolidayRepository.insert(holiday);
    }
    state = state.copyWith(
      recurringHolidays: [...state.recurringHolidays, holiday],
    );
  }

  Future<void> updateRecurringHoliday(RecurringHoliday holiday) async {
    if (hasDatabase) {
      await _db!.recurringHolidayRepository.update(holiday);
    }
    state = state.copyWith(
      recurringHolidays: state.recurringHolidays
          .map((h) => h.id == holiday.id ? holiday : h)
          .toList(),
    );
  }

  Future<void> removeRecurringHoliday(String id) async {
    if (hasDatabase) {
      await _db!.recurringHolidayRepository.delete(id);
    }
    state = state.copyWith(
      recurringHolidays: state.recurringHolidays.where((h) => h.id != id).toList(),
    );
  }

  // Groups
  Future<void> addGroup(Group group) async {
    if (hasDatabase) {
      await _db!.groupRepository.insert(group);
    }
    state = state.copyWith(groups: [...state.groups, group]);
  }

  Future<void> updateGroup(Group group) async {
    if (hasDatabase) {
      await _db!.groupRepository.update(group);
    }
    state = state.copyWith(
      groups: state.groups.map((g) => g.id == group.id ? group : g).toList(),
    );
  }

  Future<void> removeGroup(String id) async {
    if (hasDatabase) {
      await _db!.groupRepository.delete(id);
    }
    state = state.copyWith(
      groups: state.groups.where((g) => g.id != id).toList(),
    );
  }

  // Moduls
  Future<void> addModul(Modul modul) async {
    if (hasDatabase) {
      await _db!.modulRepository.insert(modul);
    }
    state = state.copyWith(moduls: [...state.moduls, modul]);
  }

  Future<void> updateModul(Modul modul) async {
    if (hasDatabase) {
      await _db!.modulRepository.update(modul);
    }
    state = state.copyWith(
      moduls: state.moduls.map((m) => m.id == modul.id ? modul : m).toList(),
    );
  }

  Future<void> removeModul(String id) async {
    if (hasDatabase) {
      await _db!.modulRepository.delete(id);
    }
    state = state.copyWith(
      moduls: state.moduls.where((m) => m.id != id).toList(),
    );
  }

  void setSelectedCicles(List<String> cicleCodes) {
    state = state.copyWith(selectedCicleIds: cicleCodes);
  }

  /// Import a module from curriculum YAML: creates Modul and RAs from UFs.
  /// If the module already exists (by code), accumulates the cicleCode.
  Future<void> importModulFromCurriculum(String cicleCode, CurriculumModul cm) async {
    // Check if module already exists by code
    final existing = state.moduls.where((m) => m.code == cm.codi).toList();
    if (existing.isNotEmpty) {
      final modul = existing.first;
      if (!modul.cicleCodes.contains(cicleCode)) {
        await updateModul(modul.copyWith(
          cicleCodes: [...modul.cicleCodes, cicleCode],
        ));
      }
      return;
    }

    // Create new module with RAs from UFs
    final ras = <RA>[];
    for (var i = 0; i < cm.ufs.length; i++) {
      final uf = cm.ufs[i];
      final raNumber = i + 1;
      ras.add(RA(
        id: nextId(),
        number: raNumber,
        code: uf.codi,
        title: uf.nom,
        durationHours: uf.hores,
        order: i,
      ));
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
  }

  /// Add or update RA in a module.
  Future<void> setModulRA(String modulId, RA ra) async {
    final list = state.moduls.where((m) => m.id == modulId).toList();
    if (list.isEmpty) return;
    final modul = list.first;
    final existing = modul.ras.where((r) => r.id == ra.id).toList();
    final ras = existing.isEmpty
        ? [...modul.ras, ra]
        : modul.ras.map((r) => r.id == ra.id ? ra : r).toList();
    await updateModul(modul.copyWith(ras: ras));
  }

  Future<void> removeModulRA(String modulId, String raId) async {
    final list = state.moduls.where((m) => m.id == modulId).toList();
    if (list.isEmpty) return;
    final modul = list.first;
    final ras = modul.ras.where((r) => r.id != raId).toList();
    await updateModul(modul.copyWith(ras: ras));
  }

  Future<void> setDailyNote(DailyNote note) async {
    final notes = state.dailyNotes.where((n) => !_isSameDailyNote(n, note)).toList();
    if (_isDailyNoteEmpty(note) && !note.completed) {
      // Delete empty note
      final existing = state.dailyNotes.where((n) => _isSameDailyNote(n, note)).toList();
      if (existing.isNotEmpty && hasDatabase) {
        await _db!.dailyNoteRepository.delete(existing.first.id);
      }
      state = state.copyWith(dailyNotes: notes);
      return;
    }

    if (hasDatabase) {
      // Check if this is an update or insert
      final existingNote = await _db!.dailyNoteRepository.findByGroupRaDate(
        note.groupId,
        note.raId,
        note.date,
      );
      if (existingNote != null) {
        // Update existing note, preserving its ID
        final updatedNote = note.copyWith(id: existingNote.id);
        await _db!.dailyNoteRepository.update(updatedNote);
        state = state.copyWith(dailyNotes: [...notes, updatedNote]);
      } else {
        // Insert new note
        await _db!.dailyNoteRepository.insert(note);
        state = state.copyWith(dailyNotes: [...notes, note]);
      }
    } else {
      // No database - just update in-memory state
      state = state.copyWith(dailyNotes: [...notes, note]);
    }
  }

  DailyNote? getDailyNote(String groupId, String raId, DateTime date) {
    final list = state.dailyNotes
        .where((n) => n.groupId == groupId && n.raId == raId && _isSameDay(n.date, date))
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
    final list = state.groups.where((g) => g.id == groupId).toList();
    if (list.isEmpty) return;
    final group = list.first;
    if (group.moduleIds.contains(modulId)) return;
    await updateGroup(group.copyWith(moduleIds: [...group.moduleIds, modulId]));
  }

  Future<void> removeModuleFromGroup(String groupId, String modulId) async {
    final list = state.groups.where((g) => g.id == groupId).toList();
    if (list.isEmpty) return;
    final group = list.first;
    await updateGroup(group.copyWith(
      moduleIds: group.moduleIds.where((id) => id != modulId).toList(),
    ));
  }

  List<Group> getGroupsForModule(String modulId) {
    return state.groups.where((g) => g.moduleIds.contains(modulId)).toList();
  }

  String nextId() => _uuid.v4();

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isSameDailyNote(DailyNote a, DailyNote b) {
    return a.id == b.id ||
        (a.raId == b.raId && a.groupId == b.groupId && _isSameDay(a.date, b.date));
  }

  static bool _isDailyNoteEmpty(DailyNote note) {
    return (note.plannedContent == null || note.plannedContent!.trim().isEmpty) &&
        (note.actualContent == null || note.actualContent!.trim().isEmpty) &&
        (note.notes == null || note.notes!.trim().isEmpty);
  }
}

/// Provider for app state with database persistence.
final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final db = ref.watch(databaseServiceProvider);  // Can be null
  return AppStateNotifier(db);
});
