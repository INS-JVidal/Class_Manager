import 'package:flutter_test/flutter_test.dart';

import 'package:class_activity_manager/models/models.dart';
import 'package:class_activity_manager/state/app_state.dart';

void main() {
  test('default recurring holidays are seeded', () {
    final notifier = AppStateNotifier(null);

    final holidays = notifier.state.recurringHolidays;
    expect(holidays, hasLength(12));
    expect(holidays.every((h) => h.isEnabled), isTrue);
    expect(holidays.any((h) => h.name == 'Nadal'), isTrue);
  });

  test('group-module relationships can be managed', () async {
    final notifier = AppStateNotifier(null);
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

    final updatedGroup =
        notifier.state.groups.firstWhere((g) => g.id == group.id);
    expect(updatedGroup.moduleIds, contains(modul.id));

    await notifier.removeModuleFromGroup(group.id, modul.id);
    final removedGroup =
        notifier.state.groups.firstWhere((g) => g.id == group.id);
    expect(removedGroup.moduleIds, isNot(contains(modul.id)));
  });

  test('setModulRA adds and updates RAs', () async {
    final notifier = AppStateNotifier(null);
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

    final withRa =
        notifier.state.moduls.firstWhere((m) => m.id == modul.id);
    expect(withRa.ras, hasLength(1));
    expect(withRa.ras.first.title, 'Models relacionals');

    final updatedRa = ra.copyWith(title: 'Models i consultes SQL');
    await notifier.setModulRA(modul.id, updatedRa);

    final updated =
        notifier.state.moduls.firstWhere((m) => m.id == modul.id);
    expect(updated.ras, hasLength(1));
    expect(updated.ras.first.title, 'Models i consultes SQL');
  });

  test('setDailyNote adds, updates, and removes empty notes', () async {
    final notifier = AppStateNotifier(null);
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
}
