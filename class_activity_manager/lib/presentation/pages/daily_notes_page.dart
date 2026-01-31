import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';

/// Catalan day names for display.
const _catalanDayNames = [
  'Dilluns',
  'Dimarts',
  'Dimecres',
  'Dijous',
  'Divendres',
  'Dissabte',
  'Diumenge',
];

/// Calculate ISO week number for a date.
int _weekNumber(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final daysDiff = date.difference(firstDayOfYear).inDays;
  return ((daysDiff + firstDayOfYear.weekday) / 7).ceil();
}

class DailyNotesPage extends ConsumerStatefulWidget {
  const DailyNotesPage({super.key});

  @override
  ConsumerState<DailyNotesPage> createState() => _DailyNotesPageState();
}

class _DailyNotesPageState extends ConsumerState<DailyNotesPage> {
  String? _selectedGroupId;
  String? _selectedModulId;
  String? _selectedRaId;
  final ScrollController _daysController = ScrollController();
  final GlobalKey _todayKey = GlobalKey();
  String? _lastFocusToken;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  void _focusTodayIfNeeded(String? token, bool hasToday) {
    if (token == null || !hasToday || _lastFocusToken == token) {
      return;
    }
    _lastFocusToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _todayKey.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final groups = appState.groups;
    final allModuls = appState.moduls;

    // Auto-select if only one group
    if (groups.length == 1 && _selectedGroupId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedGroupId = groups.first.id);
      });
    }

    // Get selected group
    final groupList = groups.where((g) => g.id == _selectedGroupId).toList();
    final selectedGroup = groupList.isEmpty ? null : groupList.first;

    // Filter modules by selected group's moduleIds
    final moduls = selectedGroup != null
        ? allModuls.where((m) => selectedGroup.moduleIds.contains(m.id)).toList()
        : <Modul>[];

    // Auto-select if only one module
    if (moduls.length == 1 && _selectedModulId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedModulId = moduls.first.id);
      });
    }

    // Reset modulId if not in filtered list
    if (_selectedModulId != null && !moduls.any((m) => m.id == _selectedModulId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedModulId = null;
            _selectedRaId = null;
          });
        }
      });
    }

    final modulList = moduls.where((m) => m.id == _selectedModulId).toList();
    final modul = modulList.isEmpty ? null : modulList.first;
    final ras = modul?.ras ?? [];

    // Auto-select if only one RA
    if (ras.length == 1 && _selectedRaId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedRaId = ras.first.id);
      });
    }

    final raList = ras.where((r) => r.id == _selectedRaId).toList();
    final ra = raList.isEmpty ? null : raList.first;
    final isSelectedRaValid = _selectedRaId != null && ras.any((r) => r.id == _selectedRaId);

    List<DateTime> days = [];
    if (ra != null && ra.startDate != null && ra.endDate != null) {
      var d = DateTime(ra.startDate!.year, ra.startDate!.month, ra.startDate!.day);
      final end = DateTime(ra.endDate!.year, ra.endDate!.month, ra.endDate!.day);
      while (!d.isAfter(end)) {
        days.add(d);
        d = d.add(const Duration(days: 1));
      }
    }
    final today = DateTime.now();
    final todayIndex = days.indexWhere(
      (d) => d.year == today.year && d.month == today.month && d.day == today.day,
    );
    final focusToken = ra == null || _selectedGroupId == null
        ? null
        : '$_selectedGroupId-${ra.id}-${ra.startDate?.millisecondsSinceEpoch}-${ra.endDate?.millisecondsSinceEpoch}';
    _focusTodayIfNeeded(focusToken, todayIndex != -1);

    // Filter daily notes by group and RA
    final allDailyNotes = appState.dailyNotes;
    final dailyNotes = (ra != null && _selectedGroupId != null)
        ? allDailyNotes.where((n) => n.raId == ra.id && n.groupId == _selectedGroupId).toList()
        : <DailyNote>[];
    DailyNote? noteFor(DateTime date) {
      final list = dailyNotes.where((n) =>
          n.date.year == date.year && n.date.month == date.month && n.date.day == date.day).toList();
      return list.isEmpty ? null : list.first;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes diàries', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Seleccioneu grup, mòdul i RA per veure la seqüència de dies i afegir notes.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          // Selectors row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              if (isNarrow) {
                return Column(
                  children: [
                    // Group selector
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: _selectedGroupId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Grup',
                          border: OutlineInputBorder(),
                        ),
                        items: groups
                            .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedGroupId = v;
                          _selectedModulId = null;
                          _selectedRaId = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Module selector
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('modul-$_selectedGroupId'),
                        value: _selectedModulId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Mòdul',
                          border: OutlineInputBorder(),
                        ),
                        items: moduls
                            .map((m) => DropdownMenuItem(value: m.id, child: Text('${m.code} — ${m.name}')))
                            .toList(),
                        onChanged: moduls.isEmpty
                            ? null
                            : (v) => setState(() {
                                  _selectedModulId = v;
                                  _selectedRaId = null;
                                }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // RA selector
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('ra-$_selectedModulId'),
                        value: isSelectedRaValid ? _selectedRaId : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'RA',
                          border: OutlineInputBorder(),
                        ),
                        items: ras
                            .map((r) => DropdownMenuItem(value: r.id, child: Text('${r.code} — ${r.title}')))
                            .toList(),
                        onChanged: ras.isEmpty
                            ? null
                            : (v) => setState(() => _selectedRaId = v),
                      ),
                    ),
                  ],
                );
              }
              // Wide layout: 3 columns
              return Row(
                children: [
                  // Group selector
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGroupId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Grup',
                        border: OutlineInputBorder(),
                      ),
                      items: groups
                          .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedGroupId = v;
                        _selectedModulId = null;
                        _selectedRaId = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Module selector
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('modul-$_selectedGroupId'),
                      value: _selectedModulId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Mòdul',
                        border: OutlineInputBorder(),
                      ),
                      items: moduls
                          .map((m) => DropdownMenuItem(value: m.id, child: Text('${m.code} — ${m.name}')))
                          .toList(),
                      onChanged: moduls.isEmpty
                          ? null
                          : (v) => setState(() {
                                _selectedModulId = v;
                                _selectedRaId = null;
                              }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // RA selector
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('ra-$_selectedModulId'),
                      value: isSelectedRaValid ? _selectedRaId : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'RA',
                        border: OutlineInputBorder(),
                      ),
                      items: ras
                          .map((r) => DropdownMenuItem(value: r.id, child: Text('${r.code} — ${r.title}')))
                          .toList(),
                      onChanged: ras.isEmpty
                          ? null
                          : (v) => setState(() => _selectedRaId = v),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // RA info header card
          if (ra != null && modul != null && selectedGroup != null)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.school, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedGroup.name} — ${modul.code}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ra.code}: ${ra.title}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (ra != null && modul != null) const SizedBox(height: 16),
          // Content area
          if (groups.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('No hi ha grups configurats. Creeu un grup i assigneu-li mòduls.')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/grups/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear grup'),
                    ),
                  ],
                ),
              ),
            )
          else if (_selectedGroupId == null)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Seleccioneu un grup.')))
          else if (selectedGroup != null && selectedGroup.moduleIds.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text('El grup ${selectedGroup.name} no té mòduls assignats.')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/grups/edit/${selectedGroup.id}'),
                      icon: const Icon(Icons.settings),
                      label: const Text('Configurar mòduls del grup'),
                    ),
                  ],
                ),
              ),
            )
          else if (_selectedModulId == null)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Seleccioneu un mòdul.')))
          else if (ra == null && ras.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Aquest mòdul no té RAs.')))
          else if (ra == null)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Seleccioneu un RA.')))
          else if (ra.startDate == null || ra.endDate == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Configureu les dates del RA "${ra.code}" per veure els dies.')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/moduls/${modul?.id}/ra-config'),
                      icon: const Icon(Icons.date_range),
                      label: const Text('Configurar dates'),
                    ),
                  ],
                ),
              ),
            )
          else if (days.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Cap dia en el rang.')))
          else
            Expanded(
              child: ListView.builder(
                controller: _daysController,
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final date = days[index];
                  final note = noteFor(date);
                  final isToday = index == todayIndex;
                  return KeyedSubtree(
                    key: isToday ? _todayKey : null,
                    child: _DayNoteCard(
                      date: date,
                      note: note,
                      modulId: modul!.id,
                      raId: ra.id,
                      groupId: _selectedGroupId!,
                      notifier: ref.read(appStateProvider.notifier),
                      dateFormat: _dateFormat,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DayNoteCard extends StatefulWidget {
  const _DayNoteCard({
    required this.date,
    required this.note,
    required this.modulId,
    required this.raId,
    required this.groupId,
    required this.notifier,
    required this.dateFormat,
  });

  final DateTime date;
  final DailyNote? note;
  final String modulId;
  final String raId;
  final String groupId;
  final AppStateNotifier notifier;
  final DateFormat dateFormat;

  @override
  State<_DayNoteCard> createState() => _DayNoteCardState();
}

class _DayNoteCardState extends State<_DayNoteCard> {
  late TextEditingController _plannedController;
  late TextEditingController _actualController;
  late TextEditingController _notesController;
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _plannedController = TextEditingController(text: widget.note?.plannedContent ?? '');
    _actualController = TextEditingController(text: widget.note?.actualContent ?? '');
    _notesController = TextEditingController(text: widget.note?.notes ?? '');
    _completed = widget.note?.completed ?? false;
  }

  @override
  void didUpdateWidget(covariant _DayNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note?.plannedContent != oldWidget.note?.plannedContent) {
      _plannedController.text = widget.note?.plannedContent ?? '';
    }
    if (widget.note?.actualContent != oldWidget.note?.actualContent) {
      _actualController.text = widget.note?.actualContent ?? '';
    }
    if (widget.note?.notes != oldWidget.note?.notes) {
      _notesController.text = widget.note?.notes ?? '';
    }
    if (widget.note?.completed != oldWidget.note?.completed) {
      _completed = widget.note?.completed ?? false;
    }
  }

  @override
  void dispose() {
    _plannedController.dispose();
    _actualController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final id = widget.note?.id ?? widget.notifier.nextId();
    widget.notifier.setDailyNote(DailyNote(
      id: id,
      raId: widget.raId,
      modulId: widget.modulId,
      groupId: widget.groupId,
      date: widget.date,
      plannedContent: _plannedController.text.trim().isEmpty ? null : _plannedController.text.trim(),
      actualContent: _actualController.text.trim().isEmpty ? null : _actualController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      completed: _completed,
    ));
  }

  void _markComplete() {
    setState(() => _completed = true);
    _save();
  }

  String _dateDisplay() {
    final dayOfWeek = _catalanDayNames[widget.date.weekday - 1];
    final weekNum = _weekNumber(widget.date);
    return '${widget.dateFormat.format(widget.date)} · $dayOfWeek · Setmana $weekNum';
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = _completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header with completion status
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dateDisplay(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!isReadOnly)
                  FilledButton.icon(
                    onPressed: _markComplete,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Marcar com a fet'),
                  )
                else
                  Chip(
                    label: const Text('Completat'),
                    avatar: const Icon(Icons.check_circle, size: 16),
                    backgroundColor: Colors.green.shade100,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Planned content
            TextField(
              controller: _plannedController,
              decoration: const InputDecoration(
                labelText: 'Contingut planificat',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                hintText: 'Què es preveu treballar avui?',
              ),
              maxLines: 2,
              readOnly: isReadOnly,
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 12),
            // Actual content
            TextField(
              controller: _actualController,
              decoration: const InputDecoration(
                labelText: 'Contingut impartit',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                hintText: "Què s'ha treballat realment?",
              ),
              maxLines: 2,
              readOnly: isReadOnly,
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 12),
            // Additional notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observacions',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              readOnly: isReadOnly,
              onChanged: (_) => _save(),
            ),
          ],
        ),
      ),
    );
  }
}
