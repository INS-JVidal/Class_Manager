import 'vacation_period.dart';

/// Curs acadèmic amb dates i períodes de vacances.
class AcademicYear {
  AcademicYear({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.vacationPeriods = const [],
    this.isActive = true,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<VacationPeriod> vacationPeriods;
  final bool isActive;

  AcademicYear copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    List<VacationPeriod>? vacationPeriods,
    bool? isActive,
  }) {
    return AcademicYear(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      vacationPeriods: vacationPeriods ?? this.vacationPeriods,
      isActive: isActive ?? this.isActive,
    );
  }
}
