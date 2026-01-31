import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/curriculum_service.dart';
import '../../state/app_state.dart';

class SetupCurriculumPage extends ConsumerStatefulWidget {
  const SetupCurriculumPage({super.key});

  @override
  ConsumerState<SetupCurriculumPage> createState() =>
      _SetupCurriculumPageState();
}

class _SetupCurriculumPageState extends ConsumerState<SetupCurriculumPage> {
  final Set<String> _selectedCicleCodes = {};
  final Set<String> _selectedModuleKeys = {}; // "cicleCode|modulCode"
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ciclesAsync = ref.watch(curriculumCiclesProvider);
    final appState = ref.watch(appStateProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuració del currículum',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Seleccioneu els cicles que imparteix i els mòduls a importar. Els RAs es carreguen automàticament des del currículum.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ciclesAsync.when(
              data: (cicles) {
                if (cicles.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No s\'han trobat cicles al currículum.'),
                    ),
                  );
                }
                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  interactive: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pas 1: Cicles que imparteix',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: cicles.map((c) {
                                final code = c.codi;
                                final isSelected =
                                    _selectedCicleCodes.contains(code) ||
                                    appState.selectedCicleIds.contains(code);
                                return CheckboxListTile(
                                  title: Text(
                                    '${c.acronim ?? code} — ${c.nom}',
                                  ),
                                  subtitle: Text('${c.moduls.length} mòduls'),
                                  value: isSelected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedCicleCodes.add(code);
                                        ref
                                            .read(appStateProvider.notifier)
                                            .setSelectedCicles([
                                              ...{
                                                ...appState.selectedCicleIds,
                                                code,
                                              },
                                            ]);
                                      } else {
                                        _selectedCicleCodes.remove(code);
                                        ref
                                            .read(appStateProvider.notifier)
                                            .setSelectedCicles(
                                              appState.selectedCicleIds
                                                  .where((id) => id != code)
                                                  .toList(),
                                            );
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Pas 2: Mòduls a importar',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        ...cicles
                            .where(
                              (c) =>
                                  _selectedCicleCodes.contains(c.codi) ||
                                  appState.selectedCicleIds.contains(c.codi),
                            )
                            .map((cicle) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ExpansionTile(
                                  title: Text(
                                    '${cicle.acronim ?? cicle.codi} — ${cicle.nom}',
                                  ),
                                  subtitle: Text(
                                    '${cicle.moduls.length} mòduls',
                                  ),
                                  children: cicle.moduls.map((modul) {
                                    final key = '${cicle.codi}|${modul.codi}';
                                    final alreadyImported = appState.moduls.any(
                                      (m) =>
                                          m.cicleCodes.contains(cicle.codi) &&
                                          m.code == modul.codi,
                                    );
                                    final isSelected = _selectedModuleKeys
                                        .contains(key);
                                    return CheckboxListTile(
                                      title: Text(
                                        '${modul.codi} — ${modul.nom}',
                                      ),
                                      subtitle: Text(
                                        '${modul.hores} h · ${modul.ufs.length} RAs',
                                      ),
                                      value: isSelected || alreadyImported,
                                      tristate: true,
                                      onChanged: alreadyImported
                                          ? null
                                          : (v) {
                                              setState(() {
                                                if (v == true) {
                                                  _selectedModuleKeys.add(key);
                                                } else {
                                                  _selectedModuleKeys.remove(
                                                    key,
                                                  );
                                                }
                                              });
                                            },
                                    );
                                  }).toList(),
                                ),
                              );
                            }),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: _selectedModuleKeys.isEmpty
                                  ? null
                                  : () {
                                      final notifier = ref.read(
                                        appStateProvider.notifier,
                                      );
                                      for (final key in _selectedModuleKeys) {
                                        final parts = key.split('|');
                                        if (parts.length != 2) continue;
                                        final cicleCode = parts[0];
                                        final modulCode = parts[1];
                                        final cicle = cicles
                                            .where((c) => c.codi == cicleCode)
                                            .firstOrNull;
                                        if (cicle == null) continue;
                                        final modul = cicle.moduls
                                            .where((m) => m.codi == modulCode)
                                            .firstOrNull;
                                        if (modul == null) continue;
                                        notifier.importModulFromCurriculum(
                                          cicleCode,
                                          modul,
                                        );
                                      }
                                      setState(
                                        () => _selectedModuleKeys.clear(),
                                      );
                                      if (context.mounted) {
                                        context.go('/moduls');
                                      }
                                    },
                              child: const Text(
                                'Importa els mòduls seleccionats',
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => context.go('/moduls'),
                              child: const Text('Torna a Mòduls'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error en carregar el currículum: $err'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
