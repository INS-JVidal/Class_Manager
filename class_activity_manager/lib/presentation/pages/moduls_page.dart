import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../widgets/confirm_dialog.dart';

class ModulsListPage extends ConsumerWidget {
  const ModulsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final moduls = ref.watch(appStateProvider).moduls;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.modules, style: Theme.of(context).textTheme.headlineMedium),
              OutlinedButton.icon(
                onPressed: () => context.go('/setup-curriculum'),
                icon: const Icon(Icons.menu_book),
                label: Text(l10n.setupCurriculum),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: moduls.isEmpty
                ? Center(child: Text(l10n.noModules))
                : ListView.builder(
                    itemCount: moduls.length,
                    itemBuilder: (context, index) {
                      final m = moduls[index];
                      final cycleInfo = m.cicleCodes.isNotEmpty
                          ? ' · ${m.cicleCodes.join(", ")}'
                          : '';
                      return Card(
                        child: ListTile(
                          title: Text('${m.code} — ${m.name}'),
                          subtitle: Text('${m.totalHours} h$cycleInfo'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/moduls/${m.id}'),
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

class ModulFormPage extends ConsumerStatefulWidget {
  const ModulFormPage({super.key, this.modulId});

  final String? modulId;

  @override
  ConsumerState<ModulFormPage> createState() => _ModulFormPageState();
}

class _ModulFormPageState extends ConsumerState<ModulFormPage> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _hoursController = TextEditingController();
  final _objectivesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.modulId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadModul());
    }
  }

  void _loadModul() {
    final moduls = ref.read(appStateProvider).moduls;
    final modulList = moduls.where((x) => x.id == widget.modulId).toList();
    final m = modulList.isEmpty ? null : modulList.first;
    if (m != null) {
      _codeController.text = m.code;
      _nameController.text = m.name;
      _descController.text = m.description ?? '';
      _hoursController.text = m.totalHours.toString();
      _objectivesController.text = m.objectives.join('\n');
    }
  }

  Modul? get _existingModul {
    if (widget.modulId == null) return null;
    final list = ref
        .read(appStateProvider)
        .moduls
        .where((m) => m.id == widget.modulId)
        .toList();
    return list.isEmpty ? null : list.first;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _hoursController.dispose();
    _objectivesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.modulId != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? l10n.editModule : l10n.addModule,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: l10n.moduleCodeHint,
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.name,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: l10n.description,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hoursController,
            decoration: InputDecoration(
              labelText: l10n.totalHours,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _objectivesController,
            decoration: InputDecoration(
              labelText: '${l10n.objectives} (${l10n.objectivesHint})',
              border: const OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              FilledButton(
                onPressed: () {
                  final code = _codeController.text.trim();
                  final name = _nameController.text.trim();
                  final hours = int.tryParse(_hoursController.text.trim());
                  if (code.isEmpty ||
                      name.isEmpty ||
                      hours == null ||
                      hours <= 0) {
                    return;
                  }
                  final objectives = _objectivesController.text
                      .trim()
                      .split('\n')
                      .where((s) => s.trim().isNotEmpty)
                      .toList();
                  final notifier = ref.read(appStateProvider.notifier);
                  if (isEdit && _existingModul != null) {
                    notifier.updateModul(
                      _existingModul!.copyWith(
                        code: code,
                        name: name,
                        description: _descController.text.trim().isEmpty
                            ? null
                            : _descController.text.trim(),
                        totalHours: hours,
                        objectives: objectives,
                      ),
                    );
                    context.go('/moduls/${_existingModul!.id}');
                  } else {
                    final modul = Modul(
                      id: notifier.nextId(),
                      code: code,
                      name: name,
                      description: _descController.text.trim().isEmpty
                          ? null
                          : _descController.text.trim(),
                      totalHours: hours,
                      objectives: objectives,
                    );
                    notifier.addModul(modul);
                    context.go('/moduls/${modul.id}');
                  }
                },
                child: Text(l10n.save),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ModulDetailPage extends ConsumerWidget {
  const ModulDetailPage({super.key, required this.modulId});

  final String modulId;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final moduls = ref.watch(appStateProvider).moduls;
    final modulList = moduls.where((m) => m.id == modulId).toList();
    final modul = modulList.isEmpty ? null : modulList.first;
    if (modul == null) {
      return Center(child: Text(l10n.noModules));
    }
    final ras = modul.ras;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.back,
                onPressed: () => context.go('/moduls'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${modul.code} — ${modul.name}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (modul.description != null)
                      Text(
                        modul.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    Text(
                      '${l10n.totalHours}: ${modul.totalHours} h',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: l10n.editModule,
                    onPressed: () => context.go('/moduls/edit/$modulId'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: l10n.deleteModule,
                    onPressed: () async => _confirmDelete(context, ref, modul),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(l10n.ras, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/moduls/$modulId/ra/new'),
                icon: const Icon(Icons.add),
                label: Text(l10n.addRa),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.go('/moduls/$modulId/ra-config'),
                icon: const Icon(Icons.date_range),
                label: Text(l10n.selectDates),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ras.isEmpty
                ? Center(child: Text(l10n.noRas))
                : ListView.builder(
                    itemCount: ras.length,
                    itemBuilder: (context, index) {
                      final ra = ras[index];
                      final dateInfo = _buildDateInfo(ra);
                      return Card(
                        child: ListTile(
                          title: Text('${ra.code} — ${ra.title}'),
                          subtitle: Text('${ra.durationHours} h$dateInfo'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => context.go(
                                  '/moduls/$modulId/ra/edit/${ra.id}',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async =>
                                    _confirmDeleteRA(context, ref, modul, ra),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _buildDateInfo(RA ra) {
    final parts = <String>[];
    if (ra.startDate != null) {
      parts.add('Inici: ${_dateFormat.format(ra.startDate!)}');
    }
    if (ra.endDate != null) {
      parts.add('Fi: ${_dateFormat.format(ra.endDate!)}');
    }
    if (parts.isEmpty) return '';
    return ' · ${parts.join(' · ')}';
  }

  static Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Modul modul) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteModule,
      content: l10n.deleteModuleConfirm(modul.name),
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      ref.read(appStateProvider.notifier).removeModul(modul.id);
      context.go('/moduls');
    }
  }

  static Future<void> _confirmDeleteRA(
    BuildContext context,
    WidgetRef ref,
    Modul modul,
    RA ra,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteRa,
      content: l10n.deleteRaConfirm(ra.code),
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      ref.read(appStateProvider.notifier).removeModulRA(modul.id, ra.id);
    }
  }
}

class RAFormPage extends ConsumerStatefulWidget {
  const RAFormPage({super.key, required this.modulId, this.raId});

  final String modulId;
  final String? raId;

  @override
  ConsumerState<RAFormPage> createState() => _RAFormPageState();
}

class _RAFormPageState extends ConsumerState<RAFormPage> {
  final _numberController = TextEditingController();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _hoursController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.raId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadRA());
    }
  }

  void _loadRA() {
    final moduls = ref.read(appStateProvider).moduls;
    final modulList = moduls.where((m) => m.id == widget.modulId).toList();
    if (modulList.isEmpty) return;
    final modul = modulList.first;
    final raList = modul.ras.where((r) => r.id == widget.raId).toList();
    final ra = raList.isEmpty ? null : raList.first;
    if (ra != null) {
      _numberController.text = ra.number.toString();
      _codeController.text = ra.code;
      _titleController.text = ra.title;
      _descController.text = ra.description ?? '';
      _hoursController.text = ra.durationHours.toString();
    }
  }

  RA? get _existingRA {
    final moduls = ref.read(appStateProvider).moduls;
    final modulList = moduls.where((m) => m.id == widget.modulId).toList();
    if (modulList.isEmpty || widget.raId == null) return null;
    final raList = modulList.first.ras
        .where((r) => r.id == widget.raId)
        .toList();
    return raList.isEmpty ? null : raList.first;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _codeController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.raId != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? l10n.editRa : l10n.addRa,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _numberController,
            decoration: const InputDecoration(
              labelText: 'Número (1, 2, 3...)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: l10n.raCodeHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: l10n.raTitle,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: l10n.description,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hoursController,
            decoration: InputDecoration(
              labelText: l10n.durationHours,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              FilledButton(
                onPressed: () {
                  final number = int.tryParse(_numberController.text.trim());
                  final code = _codeController.text.trim();
                  final title = _titleController.text.trim();
                  final hours = int.tryParse(_hoursController.text.trim());
                  if (number == null ||
                      number < 1 ||
                      code.isEmpty ||
                      title.isEmpty ||
                      hours == null ||
                      hours <= 0) {
                    return;
                  }
                  final notifier = ref.read(appStateProvider.notifier);
                  if (isEdit && _existingRA != null) {
                    final ra = _existingRA!.copyWith(
                      number: number,
                      code: code,
                      title: title,
                      description: _descController.text.trim().isEmpty
                          ? null
                          : _descController.text.trim(),
                      durationHours: hours,
                    );
                    notifier.setModulRA(widget.modulId, ra);
                    context.go('/moduls/${widget.modulId}');
                  } else {
                    final ra = RA(
                      id: notifier.nextId(),
                      number: number,
                      code: code,
                      title: title,
                      description: _descController.text.trim().isEmpty
                          ? null
                          : _descController.text.trim(),
                      durationHours: hours,
                      order: 0,
                    );
                    notifier.setModulRA(widget.modulId, ra);
                    context.go('/moduls/${widget.modulId}');
                  }
                },
                child: Text(l10n.save),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => context.go('/moduls/${widget.modulId}'),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
