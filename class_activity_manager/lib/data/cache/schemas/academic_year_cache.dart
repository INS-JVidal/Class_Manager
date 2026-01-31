import 'package:isar/isar.dart';

part 'academic_year_cache.g.dart';

/// Isar cache schema for AcademicYear entity.
@collection
class AcademicYearCache {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String name;
  late DateTime startDate;
  late DateTime endDate;

  /// Nested VacationPeriods stored as JSON string.
  late String vacationPeriodsJson;

  @Index()
  late bool isActive;

  late DateTime lastModified;
  late bool pendingSync;
}
