import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

const _uuid = Uuid();

/// In-memory app state: academic year, holidays, groups, modules.
class AppState {
  AppState({
    this.currentYear,
    List<RecurringHoliday>? recurringHolidays,
    List<Group>? groups,
    List<Modul>? moduls,
  })  : recurringHolidays = recurringHolidays ?? [],
        groups = groups ?? [],
        moduls = moduls ?? [];

  final AcademicYear? currentYear;
  final List<RecurringHoliday> recurringHolidays;
  final List<Group> groups;
  final List<Modul> moduls;

  AppState copyWith({
    AcademicYear? currentYear,
    List<RecurringHoliday>? recurringHolidays,
    List<Group>? groups,
    List<Modul>? moduls,
  }) {
    return AppState(
      currentYear: currentYear ?? this.currentYear,
      recurringHolidays: recurringHolidays ?? this.recurringHolidays,
      groups: groups ?? this.groups,
      moduls: moduls ?? this.moduls,
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

  String nextId() => _uuid.v4();
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) => AppStateNotifier());
