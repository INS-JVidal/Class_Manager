import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/curriculum/curriculum.dart';
import '../models/models.dart';

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

  AppState copyWith({
    AcademicYear? currentYear,
    List<RecurringHoliday>? recurringHolidays,
    List<Group>? groups,
    List<Modul>? moduls,
    List<String>? selectedCicleIds,
    List<DailyNote>? dailyNotes,
  }) {
    return AppState(
      currentYear: currentYear ?? this.currentYear,
      recurringHolidays: recurringHolidays ?? this.recurringHolidays,
      groups: groups ?? this.groups,
      moduls: moduls ?? this.moduls,
      selectedCicleIds: selectedCicleIds ?? this.selectedCicleIds,
      dailyNotes: dailyNotes ?? this.dailyNotes,
    );
  }
}

/// Notifier that holds and updates [AppState]. No persistence.
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier([AppState? initial])
      : super(initial ?? AppState(recurringHolidays: _defaultRecurringHolidays()));

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
  void setCurrentYear(AcademicYear year) {
    state = state.copyWith(currentYear: year);
  }

  void updateCurrentYear(AcademicYear year) {
    state = state.copyWith(currentYear: year);
  }

  void clearCurrentYear() {
    state = state.copyWith(currentYear: null);
  }

  // Vacation periods (on current year)
  void addVacationPeriod(VacationPeriod period) {
    final year = state.currentYear;
    if (year == null) return;
    final updated = List<VacationPeriod>.from(year.vacationPeriods)..add(period);
    state = state.copyWith(
      currentYear: year.copyWith(vacationPeriods: updated),
    );
  }

  void updateVacationPeriod(VacationPeriod period) {
    final year = state.currentYear;
    if (year == null) return;
    final updated = year.vacationPeriods
        .map((p) => p.id == period.id ? period : p)
        .toList();
    state = state.copyWith(
      currentYear: year.copyWith(vacationPeriods: updated),
    );
  }

  void removeVacationPeriod(String id) {
    final year = state.currentYear;
    if (year == null) return;
    final updated = year.vacationPeriods.where((p) => p.id != id).toList();
    state = state.copyWith(
      currentYear: year.copyWith(vacationPeriods: updated),
    );
  }

  // Recurring holidays
  void addRecurringHoliday(RecurringHoliday holiday) {
    state = state.copyWith(
      recurringHolidays: [...state.recurringHolidays, holiday],
    );
  }

  void updateRecurringHoliday(RecurringHoliday holiday) {
    state = state.copyWith(
      recurringHolidays: state.recurringHolidays
          .map((h) => h.id == holiday.id ? holiday : h)
          .toList(),
    );
  }

  void removeRecurringHoliday(String id) {
    state = state.copyWith(
      recurringHolidays: state.recurringHolidays.where((h) => h.id != id).toList(),
    );
  }

  // Groups
  void addGroup(Group group) {
    state = state.copyWith(groups: [...state.groups, group]);
  }

  void updateGroup(Group group) {
    state = state.copyWith(
      groups: state.groups.map((g) => g.id == group.id ? group : g).toList(),
    );
  }

  void removeGroup(String id) {
    state = state.copyWith(
      groups: state.groups.where((g) => g.id != id).toList(),
    );
  }

  // Moduls
  void addModul(Modul modul) {
    state = state.copyWith(moduls: [...state.moduls, modul]);
  }

  void updateModul(Modul modul) {
    state = state.copyWith(
      moduls: state.moduls.map((m) => m.id == modul.id ? modul : m).toList(),
    );
  }

  void removeModul(String id) {
    state = state.copyWith(
      moduls: state.moduls.where((m) => m.id != id).toList(),
    );
  }

  void setSelectedCicles(List<String> cicleCodes) {
    state = state.copyWith(selectedCicleIds: cicleCodes);
  }

  /// Import a module from curriculum YAML: creates Modul and RAs from UFs.
  /// If the module already exists (by code), accumulates the cicleCode.
  void importModulFromCurriculum(String cicleCode, CurriculumModul cm) {
    // Check if module already exists by code
    final existing = state.moduls.where((m) => m.code == cm.codi).toList();
    if (existing.isNotEmpty) {
      final modul = existing.first;
      if (!modul.cicleCodes.contains(cicleCode)) {
        updateModul(modul.copyWith(
          cicleCodes: [...modul.cicleCodes, cicleCode],
        ));
      }
      return;
    }

    // Create new module with RAs from UFs
    final notifier = this;
    final ras = <RA>[];
    for (var i = 0; i < cm.ufs.length; i++) {
      final uf = cm.ufs[i];
      final raNumber = i + 1;
      ras.add(RA(
        id: notifier.nextId(),
        number: raNumber,
        code: uf.codi,
        title: uf.nom,
        durationHours: uf.hores,
        order: i,
      ));
    }
    final modul = Modul(
      id: notifier.nextId(),
      code: cm.codi,
      name: cm.nom,
      totalHours: cm.hores,
      ras: ras,
      cicleCodes: [cicleCode],
    );
    addModul(modul);
  }

  /// Add or update RA in a module.
  void setModulRA(String modulId, RA ra) {
    final list = state.moduls.where((m) => m.id == modulId).toList();
    if (list.isEmpty) return;
    final modul = list.first;
    final existing = modul.ras.where((r) => r.id == ra.id).toList();
    final ras = existing.isEmpty
        ? [...modul.ras, ra]
        : modul.ras.map((r) => r.id == ra.id ? ra : r).toList();
    updateModul(modul.copyWith(ras: ras));
  }

  void removeModulRA(String modulId, String raId) {
    final list = state.moduls.where((m) => m.id == modulId).toList();
    if (list.isEmpty) return;
    final modul = list.first;
    final ras = modul.ras.where((r) => r.id != raId).toList();
    updateModul(modul.copyWith(ras: ras));
  }

  void setDailyNote(DailyNote note) {
    final notes = state.dailyNotes.where((n) => !_isSameDailyNote(n, note)).toList();
    if (_isDailyNoteEmpty(note) && !note.completed) {
      state = state.copyWith(dailyNotes: notes);
      return;
    }
    state = state.copyWith(dailyNotes: [...notes, note]);
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
  void addModuleToGroup(String groupId, String modulId) {
    final list = state.groups.where((g) => g.id == groupId).toList();
    if (list.isEmpty) return;
    final group = list.first;
    if (group.moduleIds.contains(modulId)) return;
    updateGroup(group.copyWith(moduleIds: [...group.moduleIds, modulId]));
  }

  void removeModuleFromGroup(String groupId, String modulId) {
    final list = state.groups.where((g) => g.id == groupId).toList();
    if (list.isEmpty) return;
    final group = list.first;
    updateGroup(group.copyWith(
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

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) => AppStateNotifier());
