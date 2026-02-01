import 'package:intl/intl.dart';

/// Centralized date formatters for consistent date display across the app.
///
/// Using shared instances avoids creating redundant DateFormat objects.
class AppDateFormats {
  AppDateFormats._();

  /// Day/Month/Year format: "31/01/2025"
  static final dayMonthYear = DateFormat('dd/MM/yyyy');

  /// Short day/month format: "31/01"
  static final dayMonth = DateFormat('dd/MM');

  /// Month and year (Catalan): "gener 2025"
  static final monthYearCa = DateFormat('MMMM yyyy', 'ca');

  /// Full date with weekday (Catalan): "divendres, 31 gener 2025"
  static final fullDateCa = DateFormat('EEEE, d MMMM yyyy', 'ca');

  /// Weekday name only (Catalan): "divendres"
  static final weekdayCa = DateFormat('EEEE', 'ca');

  /// ISO 8601 date format: "2025-01-31"
  static final iso8601 = DateFormat('yyyy-MM-dd');
}

/// Catalan day names for manual iteration (Monday-first order).
const catalanDayNames = [
  'Dilluns',
  'Dimarts',
  'Dimecres',
  'Dijous',
  'Divendres',
  'Dissabte',
  'Diumenge',
];

/// Catalan abbreviated day names.
const catalanDayNamesShort = ['Dl', 'Dm', 'Dc', 'Dj', 'Dv', 'Ds', 'Dg'];
