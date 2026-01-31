import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';

class RaConfigPage extends ConsumerWidget {
  const RaConfigPage({super.key, required this.modulId});

  final String modulId;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduls = ref.watch(appStateProvider).moduls;
    final modulList = moduls.where((m) => m.id == modulId).toList();
    if (modulList.isEmpty) return const Center(child: Text('Mòdul no trobat'));
    final modul = modulList.first;
    final ras = modul.ras;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configurar dates i hores — ${modul.code}', style: Theme.of(context).textTheme.headlineMedium),
                  Text(modul.name, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.go('/moduls/$modulId'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Torna'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ras.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Cap RA. Importeu mòduls des de Configuració del currículum.')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: ras.length,
                itemBuilder: (context, index) {
                  final ra = ras[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${ra.code} — ${ra.title}'),
                      subtitle: Text(
                        '${ra.durationHours} h'
                        '${ra.startDate != null ? ' · Inici: ${_dateFormat.format(ra.startDate!)}' : ''}'
                        '${ra.endDate != null ? ' · Fi: ${_dateFormat.format(ra.endDate!)}' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditRaDialog(context, ref, modul, ra),
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

  static void _showEditRaDialog(BuildContext context, WidgetRef ref, Modul modul, RA ra) {
    final hoursController = TextEditingController(text: ra.durationHours.toString());
    DateTime? start = ra.startDate;
    DateTime? end = ra.endDate;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('${ra.code} — ${ra.title}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: hoursController,
                    decoration: const InputDecoration(labelText: 'Hores', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(start != null ? _dateFormat.format(start!) : 'Data d\'inici'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final initial = start ?? DateTime.now();
                      final d = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setDialogState(() => start = d);
                    },
                  ),
                  ListTile(
                    title: Text(end != null ? _dateFormat.format(end!) : 'Data de fi'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final initial = end ?? start ?? DateTime.now();
                      final d = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setDialogState(() => end = d);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel·la')),
              FilledButton(
                onPressed: () {
                  final h = int.tryParse(hoursController.text.trim());
                  if (h != null && h > 0) {
                    ref.read(appStateProvider.notifier).setModulRA(
                          modul.id,
                          ra.copyWith(durationHours: h, startDate: start, endDate: end),
                        );
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('Desa'),
              ),
            ],
          );
        },
      ),
    );
  }
}
