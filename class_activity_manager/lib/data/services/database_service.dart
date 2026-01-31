import '../datasources/mongodb_datasource.dart';
import '../repositories/academic_year_repository.dart';
import '../repositories/daily_note_repository.dart';
import '../repositories/group_repository.dart';
import '../repositories/modul_repository.dart';
import '../repositories/recurring_holiday_repository.dart';

/// High-level database service providing access to all repositories.
class DatabaseService {
  DatabaseService(this._datasource) {
    academicYearRepository = AcademicYearRepository(_datasource);
    groupRepository = GroupRepository(_datasource);
    modulRepository = ModulRepository(_datasource);
    dailyNoteRepository = DailyNoteRepository(_datasource);
    recurringHolidayRepository = RecurringHolidayRepository(_datasource);
  }

  final MongoDbDatasource _datasource;

  late final AcademicYearRepository academicYearRepository;
  late final GroupRepository groupRepository;
  late final ModulRepository modulRepository;
  late final DailyNoteRepository dailyNoteRepository;
  late final RecurringHolidayRepository recurringHolidayRepository;

  bool get isConnected => _datasource.isConnected;

  Future<void> connect() => _datasource.connect();
  Future<void> close() => _datasource.close();
}
