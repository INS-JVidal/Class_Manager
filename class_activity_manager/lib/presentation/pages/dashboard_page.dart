import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final groups = state.groups;
    final moduls = state.moduls;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Collect all active RAs (startDate <= today <= endDate)
    final activeRas = <_ActiveRaInfo>[];
    final todaysClasses = <_ActiveRaInfo>[];

    for (final group in groups) {
      for (final modulId in group.moduleIds) {
        final modulList = moduls.where((m) => m.id == modulId).toList();
        if (modulList.isEmpty) continue;
        final modul = modulList.first;

        for (final ra in modul.ras) {
          if (ra.startDate == null || ra.endDate == null) continue;

          final startDate = DateTime(
            ra.startDate!.year,
            ra.startDate!.month,
            ra.startDate!.day,
          );
          final endDate = DateTime(
            ra.endDate!.year,
            ra.endDate!.month,
            ra.endDate!.day,
          );

          // Check if today falls within the RA date range
          if (!todayDate.isBefore(startDate) && !todayDate.isAfter(endDate)) {
            final info = _ActiveRaInfo(
              group: group,
              modul: modul,
              ra: ra,
              startDate: startDate,
              endDate: endDate,
            );
            activeRas.add(info);
            todaysClasses.add(info);
          }
        }
      }
    }

    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.welcomeMessage,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.welcome}. ${l10n.today}: ${_dateFormat.format(today)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),

            // Today's Classes Section
            Row(
              children: [
                Icon(Icons.today, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.sessionsToday,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (todaysClasses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_busy,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.noSessionsToday)),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: todaysClasses
                    .map((info) => _TodayClassCard(info: info))
                    .toList(),
              ),

            const SizedBox(height: 32),

            // Active RAs Grid
            Row(
              children: [
                Icon(
                  Icons.grid_view,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.activeRas,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.raActiveCount(activeRas.length),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (activeRas.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.noRas)),
                    ],
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive grid: 1-4 columns based on width
                  final cardWidth = 280.0;
                  final crossAxisCount = (constraints.maxWidth / cardWidth)
                      .floor()
                      .clamp(1, 4);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: activeRas.length,
                    itemBuilder: (context, index) {
                      return _ActiveRaCard(info: activeRas[index]);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveRaInfo {
  const _ActiveRaInfo({
    required this.group,
    required this.modul,
    required this.ra,
    required this.startDate,
    required this.endDate,
  });

  final Group group;
  final Modul modul;
  final RA ra;
  final DateTime startDate;
  final DateTime endDate;

  double get progress {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final totalDays = endDate.difference(startDate).inDays + 1;
    final elapsedDays = todayDate.difference(startDate).inDays + 1;
    return (elapsedDays / totalDays).clamp(0.0, 1.0);
  }

  int get daysRemaining {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return endDate.difference(todayDate).inDays;
  }
}

class _TodayClassCard extends StatelessWidget {
  const _TodayClassCard({required this.info});

  final _ActiveRaInfo info;

  @override
  Widget build(BuildContext context) {
    final groupColor = info.group.color != null
        ? _hexToColor(info.group.color!)
        : null;

    return SizedBox(
      width: 320,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Navigate to daily notes for this group/RA
            context.go('/daily-notes');
          },
          child: Container(
            decoration: groupColor != null
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(color: groupColor, width: 4),
                    ),
                  )
                : null,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (groupColor != null)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: groupColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      info.group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        info.modul.code,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${info.ra.code} — ${info.ra.title}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${info.daysRemaining} dies restants',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveRaCard extends StatelessWidget {
  const _ActiveRaCard({required this.info});

  final _ActiveRaInfo info;

  static final _dateFormat = DateFormat('dd/MM');

  @override
  Widget build(BuildContext context) {
    final groupColor = info.group.color != null
        ? _hexToColor(info.group.color!)
        : null;
    final progress = info.progress;
    final progressPercent = (progress * 100).round();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/daily-notes'),
        child: Container(
          decoration: groupColor != null
              ? BoxDecoration(
                  border: Border(left: BorderSide(color: groupColor, width: 4)),
                )
              : null,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      info.group.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      info.modul.code,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  info.ra.code,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        color:
                            groupColor ?? Theme.of(context).colorScheme.primary,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$progressPercent%',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${_dateFormat.format(info.startDate)} → ${_dateFormat.format(info.endDate)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
