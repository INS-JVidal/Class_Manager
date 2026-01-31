import 'package:isar/isar.dart';

part 'recurring_holiday_cache.g.dart';

/// Isar cache schema for RecurringHoliday entity.
@collection
class RecurringHolidayCache {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String name;
  late int month;
  late int day;
  late bool isEnabled;

  late DateTime lastModified;
  late bool pendingSync;
}
