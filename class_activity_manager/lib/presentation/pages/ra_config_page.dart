import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../widgets/dual_date_picker.dart';

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
                  Text(
                    'Configurar dates i hores — ${modul.code}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    modul.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
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
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Cap RA. Importeu mòduls des de Configuració del currículum.',
                ),
              ),
            )
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
                        onPressed: () =>
                            _showEditRaDialog(context, ref, modul, ra),
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

  static void _showEditRaDialog(
    BuildContext context,
    WidgetRef ref,
    Modul modul,
    RA ra,
  ) {
    final hoursController = TextEditingController(
      text: ra.durationHours.toString(),
    );
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
                    decoration: const InputDecoration(
                      labelText: 'Hores',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.date_range),
                      title: Text(
                        start != null && end != null
                            ? '${_dateFormat.format(start!)} → ${_dateFormat.format(end!)}'
                            : start != null
                            ? 'Inici: ${_dateFormat.format(start!)}'
                            : 'Seleccionar dates',
                      ),
                      subtitle: start == null && end == null
                          ? const Text('Prem per seleccionar rang de dates')
                          : null,
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final range = await DualDatePicker.show(
                          context,
                          initialStart: start,
                          initialEnd: end,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (range != null) {
                          setDialogState(() {
                            start = range.start;
                            end = range.end;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel·la'),
              ),
              FilledButton(
                onPressed: () async {
                  final h = int.tryParse(hoursController.text.trim());
                  if (h != null && h > 0) {
                    // Validate date range if both dates are set
                    if (start != null &&
                        end != null &&
                        !start!.isBefore(end!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La data d\'inici ha de ser anterior a la data de fi',
                          ),
                        ),
                      );
                      return;
                    }
                    await ref
                        .read(appStateProvider.notifier)
                        .setModulRA(
                          modul.id,
                          ra.copyWith(
                            durationHours: h,
                            startDate: start,
                            endDate: end,
                          ),
                        );
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
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
