import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget showing two calendars side-by-side for selecting a date range.
class DualDatePicker extends StatefulWidget {
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
  State<DualDatePicker> createState() => _DualDatePickerState();
}

class _DualDatePickerState extends State<DualDatePicker> {
  late DateTime _startMonth;
  late DateTime _endMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _error;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

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
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final String title;
  final DateTime currentMonth;
  final DateTime? selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  static final _monthFormat = DateFormat('MMMM yyyy', 'ca');

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
              onPressed: () {
                final prev = DateTime(
                  currentMonth.year,
                  currentMonth.month - 1,
                );
                if (!prev.isBefore(DateTime(firstDate.year, firstDate.month))) {
                  onMonthChanged(prev);
                }
              },
            ),
            Text(
              _monthFormat.format(currentMonth),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final next = DateTime(
                  currentMonth.year,
                  currentMonth.month + 1,
                );
                if (!next.isAfter(DateTime(lastDate.year, lastDate.month))) {
                  onMonthChanged(next);
                }
              },
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

      days.add(
        GestureDetector(
          onTap: isInRange ? () => onDateSelected(date) : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
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
                  color: isSelected
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
