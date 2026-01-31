import 'package:uuid/uuid.dart';

import 'vacation_period.dart';

const _uuid = Uuid();

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

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'vacationPeriods': vacationPeriods.map((vp) => vp.toJson()).toList(),
        'isActive': isActive,
      };

  factory AcademicYear.fromJson(Map<String, dynamic> json) => AcademicYear(
        id: json['_id']?.toString() ?? _uuid.v4(),
        name: json['name'] as String,
        startDate: _parseDateTime(json['startDate']),
        endDate: _parseDateTime(json['endDate']),
        vacationPeriods: (json['vacationPeriods'] as List<dynamic>?)
                ?.map((e) => VacationPeriod.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? true,
      );

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }
}
