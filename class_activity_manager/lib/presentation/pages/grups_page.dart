import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';

class GrupsListPage extends ConsumerWidget {
  const GrupsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(appStateProvider).groups;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grups', style: Theme.of(context).textTheme.headlineMedium),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/grups/new'),
                icon: const Icon(Icons.add),
                label: const Text('Afegir grup'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: groups.isEmpty
                ? const Center(child: Text('Cap grup. Afegiu-ne un.'))
                : ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final g = groups[index];
                      final notes = g.notes ?? '';
                      final notesExcerpt = notes.isEmpty ? '' : (notes.length > 50 ? '${notes.substring(0, 50)}...' : notes);
                      return Card(
                        child: ListTile(
                          title: Text(g.name),
                          subtitle: notesExcerpt.isEmpty ? null : Text(notesExcerpt),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/grups/edit/${g.id}'),
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

class GroupFormPage extends ConsumerStatefulWidget {
  const GroupFormPage({super.key, this.groupId});

  final String? groupId;

  @override
  ConsumerState<GroupFormPage> createState() => _GroupFormPageState();
}

class _GroupFormPageState extends ConsumerState<GroupFormPage> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadGroup());
    }
  }

  void _loadGroup() {
    final groups = ref.read(appStateProvider).groups;
    final list = groups.where((g) => g.id == widget.groupId).toList();
    if (list.isEmpty) return;
    final g = list.first;
    _nameController.text = g.name;
    _notesController.text = g.notes ?? '';
  }

  Group? get _existingGroup {
    if (widget.groupId == null) return null;
    final list = ref.read(appStateProvider).groups.where((g) => g.id == widget.groupId).toList();
    return list.isEmpty ? null : list.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.groupId != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEdit ? 'Editar grup' : 'Nou grup', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nom (p.ex. DAW1-A)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (opcional)', border: OutlineInputBorder()),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              FilledButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) return;
                  final notifier = ref.read(appStateProvider.notifier);
                  if (isEdit && _existingGroup != null) {
                    notifier.updateGroup(_existingGroup!.copyWith(
                          name: name,
                          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                        ));
                    context.go('/grups');
                  } else {
                    notifier.addGroup(Group(
                      id: notifier.nextId(),
                      name: name,
                      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                    ));
                    context.go('/grups');
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
