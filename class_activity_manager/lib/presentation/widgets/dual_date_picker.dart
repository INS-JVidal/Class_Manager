import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/recurring_holiday.dart';
import '../../models/vacation_period.dart';
import '../../state/app_state.dart';

/// Shared calendar colors for day-off highlighting.
/// Used by both DualDatePicker and CalendarPage for consistency.
class CalendarColors {
  static const weekendColor = Color(0xFF616161); // Dark grey
  static const holidayColor = Color(0xFF1B3D1B); // Very dark forest green
}

/// Widget showing two calendars side-by-side for selecting a date range.
class DualDatePicker extends ConsumerStatefulWidget {
  const DualDatePicker({
    super.key,
    this.initialStart,
    this.initialEnd,
    this.firstDate,
    this.lastDate,
  });

  final DateTime? initialStart;
  final DateTime? initialEnd;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Shows a dialog with the dual date picker and returns the selected range.
  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTime? initialStart,
    DateTime? initialEnd,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 500),
          child: DualDatePicker(
            initialStart: initialStart,
            initialEnd: initialEnd,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<DualDatePicker> createState() => _DualDatePickerState();
}

class _DualDatePickerState extends ConsumerState<DualDatePicker> {
  late DateTime _startMonth;
  late DateTime _endMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _error;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  bool _isHoliday(
    DateTime date,
    List<RecurringHoliday> holidays,
    List<VacationPeriod> vacationPeriods,
  ) {
    // Check recurring holidays (enabled only)
    for (final holiday in holidays) {
      if (holiday.isEnabled &&
          holiday.month == date.month &&
          holiday.day == date.day) {
        return true;
      }
    }

    // Check vacation periods
    for (final vp in vacationPeriods) {
      if (!date.isBefore(vp.startDate) && !date.isAfter(vp.endDate)) {
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStart;
    _endDate = widget.initialEnd;
    _startMonth = widget.initialStart ?? DateTime.now();
    _endMonth = widget.initialEnd ?? DateTime.now();
  }

  DateTime get _firstDate => widget.firstDate ?? DateTime(2020);
  DateTime get _lastDate => widget.lastDate ?? DateTime(2030);

  void _validateDates() {
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      _error = 'La data de fi no pot ser anterior a la data d\'inici';
    } else {
      _error = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final vacationPeriods = state.currentYear?.vacationPeriods ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Seleccionar dates',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Start date calendar
                Expanded(
                  child: _CalendarPanel(
                    title: 'Data d\'inici',
                    currentMonth: _startMonth,
                    selectedDate: _startDate,
                    firstDate: _firstDate,
                    lastDate: _lastDate,
                    recurringHolidays: state.recurringHolidays,
                    vacationPeriods: vacationPeriods,
                    isWeekend: _isWeekend,
                    isHoliday: _isHoliday,
                    onMonthChanged: (m) => setState(() => _startMonth = m),
                    onDateSelected: (d) {
                      setState(() {
                        _startDate = d;
                        _validateDates();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // End date calendar
                Expanded(
                  child: _CalendarPanel(
                    title: 'Data de fi',
                    currentMonth: _endMonth,
                    selectedDate: _endDate,
                    firstDate: _firstDate,
                    lastDate: _lastDate,
                    recurringHolidays: state.recurringHolidays,
                    vacationPeriods: vacationPeriods,
                    isWeekend: _isWeekend,
                    isHoliday: _isHoliday,
                    onMonthChanged: (m) => setState(() => _endMonth = m),
                    onDateSelected: (d) {
                      setState(() {
                        _endDate = d;
                        _validateDates();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_startDate != null || _endDate != null)
                Text(
                  '${_startDate != null ? _dateFormat.format(_startDate!) : '—'} → ${_endDate != null ? _dateFormat.format(_endDate!) : '—'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel·la'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed:
                    _error == null && _startDate != null && _endDate != null
                    ? () => Navigator.of(
                        context,
                      ).pop(DateTimeRange(start: _startDate!, end: _endDate!))
                    : null,
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.title,
    required this.currentMonth,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.recurringHolidays,
    required this.vacationPeriods,
    required this.isWeekend,
    required this.isHoliday,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final String title;
  final DateTime currentMonth;
  final DateTime? selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<RecurringHoliday> recurringHolidays;
  final List<VacationPeriod> vacationPeriods;
  final bool Function(DateTime) isWeekend;
  final bool Function(DateTime, List<RecurringHoliday>, List<VacationPeriod>)
  isHoliday;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  static final _monthFormat = DateFormat('MMMM yyyy', 'ca');

  bool _canGoToPreviousMonth() {
    final prev = DateTime(currentMonth.year, currentMonth.month - 1);
    return !prev.isBefore(DateTime(firstDate.year, firstDate.month));
  }

  bool _canGoToNextMonth() {
    final next = DateTime(currentMonth.year, currentMonth.month + 1);
    return !next.isAfter(DateTime(lastDate.year, lastDate.month));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _canGoToPreviousMonth()
                  ? () {
                      final prev = DateTime(
                        currentMonth.year,
                        currentMonth.month - 1,
                      );
                      onMonthChanged(prev);
                    }
                  : null,
            ),
            Text(
              _monthFormat.format(currentMonth),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _canGoToNextMonth()
                  ? () {
                      final next = DateTime(
                        currentMonth.year,
                        currentMonth.month + 1,
                      );
                      onMonthChanged(next);
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Day headers
        Row(
          children: ['Dl', 'Dt', 'Dc', 'Dj', 'Dv', 'Ds', 'Dg']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        Expanded(child: _buildCalendarGrid(context)),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );
    // Monday = 1, so we adjust for Monday-first week
    final startWeekday = (firstDayOfMonth.weekday - 1) % 7;

    final days = <Widget>[];

    // Empty cells before first day
    for (var i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }

    // Days of month
    for (var day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      final isSelected =
          selectedDate != null &&
          selectedDate!.year == date.year &&
          selectedDate!.month == date.month &&
          selectedDate!.day == date.day;
      final isToday =
          DateTime.now().year == date.year &&
          DateTime.now().month == date.month &&
          DateTime.now().day == date.day;
      final isInRange = !date.isBefore(firstDate) && !date.isAfter(lastDate);

      // Check if day is off (weekend or holiday)
      final isWeekendDay = isWeekend(date);
      final isHolidayDay = isHoliday(date, recurringHolidays, vacationPeriods);
      final isDayOff = isWeekendDay || isHolidayDay;

      days.add(
        GestureDetector(
          onTap: isInRange && !isDayOff ? () => onDateSelected(date) : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isHolidayDay
                  ? CalendarColors.holidayColor
                  : isWeekendDay
                  ? CalendarColors.weekendColor
                  : isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isToday
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isDayOff
                      ? Colors.white70
                      : isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : isInRange
                      ? null
                      : Theme.of(context).colorScheme.outline,
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: days,
    );
  }
}
