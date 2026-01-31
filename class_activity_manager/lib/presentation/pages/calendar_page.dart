import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';

/// Full calendar view page showing scheduled RAs by date.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  static final _monthFormat = DateFormat('MMMM yyyy', 'ca');
  static final _dateFormat = DateFormat('EEEE, d MMMM yyyy', 'ca');

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  bool _isHoliday(DateTime date, AppState state) {
    // Check recurring holidays (enabled only)
    for (final holiday in state.recurringHolidays) {
      if (holiday.isEnabled &&
          holiday.month == date.month &&
          holiday.day == date.day) {
        return true;
      }
    }

    // Check vacation periods in current academic year
    final vacations = state.currentYear?.vacationPeriods ?? [];
    for (final vp in vacations) {
      if (!date.isBefore(vp.startDate) && !date.isAfter(vp.endDate)) {
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final groups = state.groups;
    final moduls = state.moduls;

    // Build a map of date -> list of (group, modul, ra) info for this month
    final rasByDate = <DateTime, List<_RaInfo>>{};

    for (final group in groups) {
      for (final modulId in group.moduleIds) {
        final modulList = moduls.where((m) => m.id == modulId).toList();
        if (modulList.isEmpty) continue;
        final modul = modulList.first;

        for (final ra in modul.ras) {
          if (ra.startDate == null || ra.endDate == null) continue;

          // Check if RA overlaps with current month
          final monthStart = DateTime(
            _currentMonth.year,
            _currentMonth.month,
            1,
          );
          final monthEnd = DateTime(
            _currentMonth.year,
            _currentMonth.month + 1,
            0,
          );

          if (ra.endDate!.isBefore(monthStart) ||
              ra.startDate!.isAfter(monthEnd)) {
            continue;
          }

          // Add all days in range that fall within this month
          var date = ra.startDate!;
          while (!date.isAfter(ra.endDate!)) {
            if (date.month == _currentMonth.month &&
                date.year == _currentMonth.year) {
              final key = DateTime(date.year, date.month, date.day);
              rasByDate.putIfAbsent(key, () => []);
              rasByDate[key]!.add(_RaInfo(group: group, modul: modul, ra: ra));
            }
            date = date.add(const Duration(days: 1));
          }
        }
      }
    }

    // Get RAs for selected date
    final selectedDateKey = _selectedDate != null
        ? DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          )
        : null;
    final selectedRas = selectedDateKey != null
        ? (rasByDate[selectedDateKey] ?? [])
        : <_RaInfo>[];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar section
          Expanded(
            flex: 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Month navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              _currentMonth = DateTime(
                                _currentMonth.year,
                                _currentMonth.month - 1,
                              );
                            });
                          },
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _monthFormat.format(_currentMonth),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _currentMonth = DateTime.now();
                                  _selectedDate = DateTime.now();
                                });
                              },
                              child: const Text('Avui'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              _currentMonth = DateTime(
                                _currentMonth.year,
                                _currentMonth.month + 1,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Day headers
                    Row(
                      children:
                          [
                                'Dilluns',
                                'Dimarts',
                                'Dimecres',
                                'Dijous',
                                'Divendres',
                                'Dissabte',
                                'Diumenge',
                              ]
                              .map(
                                (d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                          ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 8),
                    // Calendar grid
                    Expanded(child: _buildCalendarGrid(context, rasByDate, state)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Selected day details
          Expanded(
            flex: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDate != null
                          ? _dateFormat.format(_selectedDate!)
                          : 'Selecciona un dia',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (selectedRas.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cap sessió programada',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: selectedRas.length,
                          itemBuilder: (context, index) {
                            final info = selectedRas[index];
                            final groupColor = info.group.color != null
                                ? _hexToColor(info.group.color!)
                                : Theme.of(context).colorScheme.primary;
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  context.go('/daily-notes');
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: groupColor,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            info.group.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
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
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              info.modul.code,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${info.ra.code} — ${info.ra.title}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (selectedRas.isNotEmpty) ...[
                      const Divider(),
                      FilledButton.tonalIcon(
                        onPressed: () => context.go('/daily-notes'),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Anar a notes diàries'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    Map<DateTime, List<_RaInfo>> rasByDate,
    AppState state,
  ) {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    // Monday = 1, so we adjust for Monday-first week
    final startWeekday = (firstDayOfMonth.weekday - 1) % 7;

    final days = <Widget>[];

    // Empty cells before first day
    for (var i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Day-off colors
    const weekendColor = Color(0xFF616161); // Dark grey
    const holidayColor = Color(0xFF1B3D1B); // Very dark forest green

    // Days of month
    for (var day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isToday = todayDate == date;
      final isSelected =
          _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final ras = rasByDate[date] ?? [];

      // Check if day is off (weekend or holiday)
      final isWeekend = _isWeekend(date);
      final isHoliday = _isHoliday(date, state);
      final isDayOff = isWeekend || isHoliday;

      // Get unique colors from RAs on this day
      final colors = ras
          .where((info) => info.group.color != null)
          .map((info) => _hexToColor(info.group.color!))
          .toSet()
          .toList();

      days.add(
        InkWell(
          onTap: isDayOff ? null : () => setState(() => _selectedDate = date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isHoliday
                  ? holidayColor
                  : isWeekend
                      ? weekendColor
                      : isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isDayOff
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : isSelected && !isDayOff
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1,
                        )
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isToday || isSelected ? FontWeight.bold : null,
                    color: isDayOff
                        ? Colors.white70
                        : isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                  ),
                ),
                if (colors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: colors
                          .take(4)
                          .map(
                            (c) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (ras.isNotEmpty && colors.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 1.2,
      children: days,
    );
  }
}

class _RaInfo {
  const _RaInfo({required this.group, required this.modul, required this.ra});
  final Group group;
  final Modul modul;
  final RA ra;
}

Color _hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 7) buffer.write('FF');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
