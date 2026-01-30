import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';

class ConfiguracioPage extends ConsumerWidget {
  const ConfiguracioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuració',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _AcademicYearSection(currentYear: state.currentYear),
          const SizedBox(height: 32),
          _VacationPeriodsSection(
            periods: state.currentYear?.vacationPeriods ?? [],
            onAdd: () => _showAddVacationPeriod(context, ref),
            onEdit: (p) => _showEditVacationPeriod(context, ref, p),
            onRemove: (p) => _confirmRemoveVacationPeriod(context, ref, p),
          ),
          const SizedBox(height: 32),
          _RecurringHolidaysSection(
            holidays: state.recurringHolidays,
            onAdd: () => _showAddRecurringHoliday(context, ref),
            onEdit: (h) => _showEditRecurringHoliday(context, ref, h),
            onRemove: (h) => _confirmRemoveRecurringHoliday(context, ref, h),
            onToggle: (h) => ref.read(appStateProvider.notifier).updateRecurringHoliday(h.copyWith(isEnabled: !h.isEnabled)),
          ),
        ],
      ),
    );
  }

  static void _showAddVacationPeriod(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _VacationPeriodFormDialog(
        onSave: (name, start, end, note) {
          final notifier = ref.read(appStateProvider.notifier);
          notifier.addVacationPeriod(VacationPeriod(
            id: notifier.nextId(),
            name: name,
            startDate: start,
            endDate: end,
            note: note.isEmpty ? null : note,
          ));
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  static void _showEditVacationPeriod(BuildContext context, WidgetRef ref, VacationPeriod p) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _VacationPeriodFormDialog(
        initialName: p.name,
        initialStart: p.startDate,
        initialEnd: p.endDate,
        initialNote: p.note ?? '',
        onSave: (name, start, end, note) {
          ref.read(appStateProvider.notifier).updateVacationPeriod(p.copyWith(
                name: name,
                startDate: start,
                endDate: end,
                note: note.isEmpty ? null : note,
              ));
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  static void _confirmRemoveVacationPeriod(BuildContext context, WidgetRef ref, VacationPeriod p) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar període'),
        content: Text('Esteu segur que voleu eliminar "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel·la')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    ).then((ok) {
      if (ok == true) ref.read(appStateProvider.notifier).removeVacationPeriod(p.id);
    });
  }

  static void _showAddRecurringHoliday(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _RecurringHolidayFormDialog(
        onSave: (name, month, day, enabled) {
          final notifier = ref.read(appStateProvider.notifier);
          notifier.addRecurringHoliday(RecurringHoliday(
            id: notifier.nextId(),
            name: name,
            month: month,
            day: day,
            isEnabled: enabled,
          ));
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  static void _showEditRecurringHoliday(BuildContext context, WidgetRef ref, RecurringHoliday h) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _RecurringHolidayFormDialog(
        initialName: h.name,
        initialMonth: h.month,
        initialDay: h.day,
        initialEnabled: h.isEnabled,
        onSave: (name, month, day, enabled) {
          ref.read(appStateProvider.notifier).updateRecurringHoliday(h.copyWith(
                name: name,
                month: month,
                day: day,
                isEnabled: enabled,
              ));
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  static void _confirmRemoveRecurringHoliday(BuildContext context, WidgetRef ref, RecurringHoliday h) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar festiu'),
        content: Text('Esteu segur que voleu eliminar "${h.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel·la')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Elimina')),
        ],
      ),
    ).then((ok) {
      if (ok == true) ref.read(appStateProvider.notifier).removeRecurringHoliday(h.id);
    });
  }
}

class _AcademicYearSection extends ConsumerStatefulWidget {
  const _AcademicYearSection({required this.currentYear});

  final AcademicYear? currentYear;

  @override
  ConsumerState<_AcademicYearSection> createState() => _AcademicYearSectionState();
}

class _AcademicYearSectionState extends ConsumerState<_AcademicYearSection> {
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.currentYear != null) {
      _nameController.text = widget.currentYear!.name;
      _startDate = widget.currentYear!.startDate;
      _endDate = widget.currentYear!.endDate;
    }
  }

  @override
  void didUpdateWidget(covariant _AcademicYearSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentYear != oldWidget.currentYear && widget.currentYear != null) {
      _nameController.text = widget.currentYear!.name;
      _startDate = widget.currentYear!.startDate;
      _endDate = widget.currentYear!.endDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Curs acadèmic', style: Theme.of(context).textTheme.titleLarge),
            if (widget.currentYear == null) ...[
              const SizedBox(height: 12),
              const Text('Encara no hi ha cap curs acadèmic. Creeu-ne un.'),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom (p.ex. 2025-2026)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_startDate != null ? _dateFormat.format(_startDate!) : 'Data d\'inici'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _startDate = d);
                },
              ),
              ListTile(
                title: Text(_endDate != null ? _dateFormat.format(_endDate!) : 'Data de fi'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _endDate = d);
                },
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty || _startDate == null || _endDate == null) return;
                  ref.read(appStateProvider.notifier).setCurrentYear(AcademicYear(
                        id: ref.read(appStateProvider.notifier).nextId(),
                        name: name,
                        startDate: _startDate!,
                        endDate: _endDate!,
                      ));
                },
                child: const Text('Crea curs acadèmic'),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text('${widget.currentYear!.name} — ${_dateFormat.format(widget.currentYear!.startDate)} – ${_dateFormat.format(widget.currentYear!.endDate)}'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => _EditAcademicYearDialog(
                      currentYear: widget.currentYear!,
                      onSave: (name, start, end) {
                        ref.read(appStateProvider.notifier).updateCurrentYear(widget.currentYear!.copyWith(
                              name: name,
                              startDate: start,
                              endDate: end,
                            ));
                        Navigator.of(ctx).pop();
                      },
                    ),
                  );
                },
                child: const Text('Edita'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VacationPeriodsSection extends StatelessWidget {
  const _VacationPeriodsSection({
    required this.periods,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<VacationPeriod> periods;
  final VoidCallback onAdd;
  final void Function(VacationPeriod) onEdit;
  final void Function(VacationPeriod) onRemove;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Períodes de vacances', style: Theme.of(context).textTheme.titleLarge),
                FilledButton.tonalIcon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Afegir període')),
              ],
            ),
            const SizedBox(height: 12),
            if (periods.isEmpty)
              const Text('Cap període definit.')
            else
              ...periods.map((p) => ListTile(
                    title: Text(p.name),
                    subtitle: Text('${_dateFormat.format(p.startDate)} – ${_dateFormat.format(p.endDate)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => onEdit(p)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => onRemove(p)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _RecurringHolidaysSection extends StatelessWidget {
  const _RecurringHolidaysSection({
    required this.holidays,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onToggle,
  });

  final List<RecurringHoliday> holidays;
  final VoidCallback onAdd;
  final void Function(RecurringHoliday) onEdit;
  final void Function(RecurringHoliday) onRemove;
  final void Function(RecurringHoliday) onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Festius recurrents', style: Theme.of(context).textTheme.titleLarge),
                FilledButton.tonalIcon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Afegir festiu')),
              ],
            ),
            const SizedBox(height: 12),
            if (holidays.isEmpty)
              const Text('Cap festiu definit.')
            else
              ...holidays.map((h) => ListTile(
                    title: Text(h.name),
                    subtitle: Text('${h.day.toString().padLeft(2, '0')}/${h.month.toString().padLeft(2, '0')}'),
                    leading: Switch(
                      value: h.isEnabled,
                      onChanged: (_) => onToggle(h),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => onEdit(h)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => onRemove(h)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _EditAcademicYearDialog extends StatefulWidget {
  const _EditAcademicYearDialog({
    required this.currentYear,
    required this.onSave,
  });

  final AcademicYear currentYear;
  final void Function(String name, DateTime start, DateTime end) onSave;

  @override
  State<_EditAcademicYearDialog> createState() => _EditAcademicYearDialogState();
}

class _EditAcademicYearDialogState extends State<_EditAcademicYearDialog> {
  late final TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime _endDate;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentYear.name);
    _startDate = widget.currentYear.startDate;
    _endDate = widget.currentYear.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edita curs acadèmic'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text(_dateFormat.format(_startDate)),
              subtitle: const Text('Data d\'inici'),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (d != null) setState(() => _startDate = d);
              },
            ),
            ListTile(
              title: Text(_dateFormat.format(_endDate)),
              subtitle: const Text('Data de fi'),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (d != null) setState(() => _endDate = d);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel·la')),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            widget.onSave(name, _startDate, _endDate);
          },
          child: const Text('Desa'),
        ),
      ],
    );
  }
}

class _VacationPeriodFormDialog extends StatefulWidget {
  _VacationPeriodFormDialog({
    this.initialName = '',
    DateTime? initialStart,
    DateTime? initialEnd,
    this.initialNote = '',
    required this.onSave,
  })  : initialStart = initialStart ?? DateTime(2024, 9, 1),
        initialEnd = initialEnd ?? DateTime(2025, 6, 30);

  final String initialName;
  final DateTime initialStart;
  final DateTime initialEnd;
  final String initialNote;
  final void Function(String name, DateTime start, DateTime end, String note) onSave;

  @override
  State<_VacationPeriodFormDialog> createState() => _VacationPeriodFormDialogState();
}

class _VacationPeriodFormDialogState extends State<_VacationPeriodFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  late DateTime _start;
  late DateTime _end;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _noteController = TextEditingController(text: widget.initialNote);
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Període de vacances'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_dateFormat.format(_start)),
              subtitle: const Text('Data d\'inici'),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) setState(() => _start = d);
              },
            ),
            ListTile(
              title: Text(_dateFormat.format(_end)),
              subtitle: const Text('Data de fi'),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _end, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) setState(() => _end = d);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Nota (opcional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel·la')),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            widget.onSave(name, _start, _end, _noteController.text.trim());
          },
          child: const Text('Desa'),
        ),
      ],
    );
  }
}

class _RecurringHolidayFormDialog extends StatefulWidget {
  const _RecurringHolidayFormDialog({
    this.initialName = '',
    this.initialMonth = 1,
    this.initialDay = 1,
    this.initialEnabled = true,
    required this.onSave,
  });

  final String initialName;
  final int initialMonth;
  final int initialDay;
  final bool initialEnabled;
  final void Function(String name, int month, int day, bool enabled) onSave;

  @override
  State<_RecurringHolidayFormDialog> createState() => _RecurringHolidayFormDialogState();
}

class _RecurringHolidayFormDialogState extends State<_RecurringHolidayFormDialog> {
  late final TextEditingController _nameController;
  late int _month;
  late int _day;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _month = widget.initialMonth;
    _day = widget.initialDay;
    _enabled = widget.initialEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Festiu recurrent'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _month,
                    decoration: const InputDecoration(labelText: 'Mes', border: OutlineInputBorder()),
                    items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(m.toString()))).toList(),
                    onChanged: (v) => setState(() => _month = v ?? 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _day.clamp(1, 31),
                    decoration: const InputDecoration(labelText: 'Dia', border: OutlineInputBorder()),
                    items: List.generate(31, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text(d.toString()))).toList(),
                    onChanged: (v) => setState(() => _day = v ?? 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Actiu'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel·la')),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            widget.onSave(name, _month, _day.clamp(1, 31), _enabled);
          },
          child: const Text('Desa'),
        ),
      ],
    );
  }
}
