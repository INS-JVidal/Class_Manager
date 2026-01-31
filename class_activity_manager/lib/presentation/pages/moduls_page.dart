import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';

class ModulsListPage extends ConsumerWidget {
  const ModulsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduls = ref.watch(appStateProvider).moduls;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mòduls', style: Theme.of(context).textTheme.headlineMedium),
              OutlinedButton.icon(
                onPressed: () => context.go('/setup-curriculum'),
                icon: const Icon(Icons.menu_book),
                label: const Text('Configuració currículum'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: moduls.isEmpty
                ? const Center(child: Text('Cap mòdul.'))
                : ListView.builder(
                    itemCount: moduls.length,
                    itemBuilder: (context, index) {
                      final m = moduls[index];
                      final cycleInfo = m.cicleCodes.isNotEmpty ? ' · ${m.cicleCodes.join(", ")}' : '';
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
    final list = ref.read(appStateProvider).moduls.where((m) => m.id == widget.modulId).toList();
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
    final isEdit = widget.modulId != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEdit ? 'Editar mòdul' : 'Nou mòdul', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: 'Codi (p.ex. MP06)', border: OutlineInputBorder()),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Descripció (opcional)', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hoursController,
            decoration: const InputDecoration(labelText: 'Total hores', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _objectivesController,
            decoration: const InputDecoration(labelText: 'Objectius (un per línia)', border: OutlineInputBorder()),
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
                  if (code.isEmpty || name.isEmpty || hours == null || hours <= 0) return;
                  final objectives = _objectivesController.text.trim().split('\n').where((s) => s.trim().isNotEmpty).toList();
                  final notifier = ref.read(appStateProvider.notifier);
                  if (isEdit && _existingModul != null) {
                    notifier.updateModul(_existingModul!.copyWith(
                          code: code,
                          name: name,
                          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                          totalHours: hours,
                          objectives: objectives,
                        ));
                    context.go('/moduls/${_existingModul!.id}');
                  } else {
                    final modul = Modul(
                      id: notifier.nextId(),
                      code: code,
                      name: name,
                      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                      totalHours: hours,
                      objectives: objectives,
                    );
                    notifier.addModul(modul);
                    context.go('/moduls/${modul.id}');
                  }
                },
                child: const Text('Desa'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel·la'),
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
    final moduls = ref.watch(appStateProvider).moduls;
    final modulList = moduls.where((m) => m.id == modulId).toList();
    final modul = modulList.isEmpty ? null : modulList.first;
    if (modul == null) {
      return const Center(child: Text('Mòdul no trobat'));
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
                tooltip: 'Tornar a Mòduls',
                onPressed: () => context.go('/moduls'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${modul.code} — ${modul.name}', style: Theme.of(context).textTheme.headlineMedium),
                    if (modul.description != null) Text(modul.description!, style: Theme.of(context).textTheme.bodyMedium),
                    Text('Total: ${modul.totalHours} h', style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar mòdul',
                    onPressed: () => context.go('/moduls/edit/$modulId'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Eliminar mòdul',
                    onPressed: () => _confirmDelete(context, ref, modul),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('RAs', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/moduls/$modulId/ra/new'),
                icon: const Icon(Icons.add),
                label: const Text('Afegir RA'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.go('/moduls/$modulId/ra-config'),
                icon: const Icon(Icons.date_range),
                label: const Text('Configurar dates'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ras.isEmpty
                ? const Center(child: Text('Cap RA. Afegiu-ne un.'))
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
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/moduls/$modulId/ra/edit/${ra.id}')),
                              IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDeleteRA(context, ref, modul, ra)),
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

  static void _confirmDelete(BuildContext context, WidgetRef ref, Modul modul) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar mòdul'),
        content: Text('Esteu segur que voleu eliminar "${modul.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel·la')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Elimina')),
        ],
      ),
    ).then((ok) {
      if (ok == true) {
        ref.read(appStateProvider.notifier).removeModul(modul.id);
        if (context.mounted) context.go('/moduls');
      }
    });
  }

  static void _confirmDeleteRA(BuildContext context, WidgetRef ref, Modul modul, RA ra) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar RA'),
        content: Text('Esteu segur que voleu eliminar "${ra.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel·la')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Elimina')),
        ],
      ),
    ).then((ok) {
      if (ok == true) {
        ref.read(appStateProvider.notifier).removeModulRA(modul.id, ra.id);
      }
    });
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
    final raList = modulList.first.ras.where((r) => r.id == widget.raId).toList();
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
    final isEdit = widget.raId != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEdit ? 'Editar RA' : 'Nou RA', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _numberController,
            decoration: const InputDecoration(labelText: 'Número (1, 2, 3...)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: 'Codi (p.ex. RA1)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Títol', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Descripció (opcional)', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hoursController,
            decoration: const InputDecoration(labelText: 'Durada (hores)', border: OutlineInputBorder()),
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
                  if (number == null || number < 1 || code.isEmpty || title.isEmpty || hours == null || hours <= 0) return;
                  final notifier = ref.read(appStateProvider.notifier);
                  if (isEdit && _existingRA != null) {
                    final ra = _existingRA!.copyWith(
                      number: number,
                      code: code,
                      title: title,
                      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
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
                      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                      durationHours: hours,
                      order: 0,
                    );
                    notifier.setModulRA(widget.modulId, ra);
                    context.go('/moduls/${widget.modulId}');
                  }
                },
                child: const Text('Desa'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => context.go('/moduls/${widget.modulId}'),
                child: const Text('Cancel·la'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
