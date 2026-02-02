import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../widgets/confirm_dialog.dart';

class GrupsListPage extends ConsumerWidget {
  const GrupsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final groups = ref.watch(appStateProvider).groups;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.groups,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/grups/new'),
                icon: const Icon(Icons.add),
                label: Text(l10n.addGroup),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: groups.isEmpty
                ? Center(child: Text(l10n.noGroups))
                : ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final g = groups[index];
                      final moduleCount = g.moduleIds.length;
                      final moduleText = moduleCount == 0
                          ? l10n.noModulesAssigned
                          : '$moduleCount ${l10n.modules}';
                      return Card(
                        child: ListTile(
                          leading: g.color != null
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _hexToColor(g.color!),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          title: Text(g.name),
                          subtitle: Text(moduleText),
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

/// Preset colors for group selection.
const _presetColors = [
  '#4CAF50', // Green
  '#2196F3', // Blue
  '#FF9800', // Orange
  '#9C27B0', // Purple
  '#F44336', // Red
  '#00BCD4', // Cyan
  '#795548', // Brown
  '#607D8B', // Blue Grey
];

Color _hexToColor(String hex) {
  // Validate hex format: #RRGGBB or #AARRGGBB
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length != 6 && cleaned.length != 8) {
    return Colors.grey; // Fallback for invalid format
  }
  // Validate all characters are valid hex digits
  if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(cleaned)) {
    return Colors.grey; // Fallback for invalid characters
  }
  final buffer = StringBuffer();
  if (cleaned.length == 6) buffer.write('FF');
  buffer.write(cleaned);
  return Color(int.parse(buffer.toString(), radix: 16));
}

class _GroupFormPageState extends ConsumerState<GroupFormPage> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  Set<String> _selectedModuleIds = {};
  String? _selectedColor;

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
    setState(() {
      _selectedModuleIds = g.moduleIds.toSet();
      _selectedColor = g.color;
    });
  }

  Group? get _existingGroup {
    if (widget.groupId == null) return null;
    final list = ref
        .read(appStateProvider)
        .groups
        .where((g) => g.id == widget.groupId)
        .toList();
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
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.groupId != null;
    final moduls = ref.watch(appStateProvider).moduls;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? l10n.editGroup : l10n.addGroup,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.groupNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            // Color selection section
            Text(
              l10n.groupColor,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.groupColorHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColors.map((hex) {
                final isSelected = _selectedColor == hex;
                final color = _hexToColor(hex);
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            if (_selectedColor != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _selectedColor = null),
                icon: const Icon(Icons.clear, size: 16),
                label: Text(l10n.clear),
              ),
            ],
            const SizedBox(height: 24),
            // Module selection section
            Text(
              l10n.groupModules,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.assignModule,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (moduls.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.noModules)),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Column(
                  children: moduls.map((m) {
                    final isSelected = _selectedModuleIds.contains(m.id);
                    final cycleInfo = m.cicleCodes.isNotEmpty
                        ? ' (${m.cicleCodes.join(", ")})'
                        : '';
                    return CheckboxListTile(
                      title: Text('${m.code} — ${m.name}$cycleInfo'),
                      subtitle: Text('${m.totalHours} h · ${m.ras.length} RAs'),
                      value: isSelected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedModuleIds.add(m.id);
                          } else {
                            _selectedModuleIds.remove(m.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                FilledButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    final notifier = ref.read(appStateProvider.notifier);
                    final moduleIds = _selectedModuleIds.toList();
                    final notes = _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim();
                    if (isEdit && _existingGroup != null) {
                      await notifier.updateGroup(
                        _existingGroup!.copyWith(
                          name: name,
                          notes: notes,
                          moduleIds: moduleIds,
                          color: _selectedColor,
                        ),
                      );
                      if (context.mounted) context.go('/grups');
                    } else {
                      await notifier.addGroup(
                        Group(
                          id: notifier.nextId(),
                          name: name,
                          notes: notes,
                          moduleIds: moduleIds,
                          color: _selectedColor,
                        ),
                      );
                      if (context.mounted) context.go('/grups');
                    }
                  },
                  child: Text(l10n.save),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.cancel),
                ),
                if (isEdit) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: l10n.deleteGroup,
                        content: l10n.deleteGroupConfirm(_nameController.text),
                        isDestructive: true,
                      );
                      if (confirmed && context.mounted) {
                        await ref
                            .read(appStateProvider.notifier)
                            .removeGroup(widget.groupId!);
                        if (context.mounted) context.go('/grups');
                      }
                    },
                    child: Text(
                      l10n.deleteGroup,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
