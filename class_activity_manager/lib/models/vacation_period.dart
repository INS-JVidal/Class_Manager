import '../core/utils/date_formats.dart';

const _absent = _Absent();

class _Absent {
  const _Absent();
}

/// Període de vacances específic d'un curs acadèmic (Nadal, Setmana Santa).
class VacationPeriod {
  VacationPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.note,
  }) : assert(!startDate.isAfter(endDate), 'startDate must be <= endDate');

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? note;

  VacationPeriod copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    Object? note = _absent,
  }) {
    return VacationPeriod(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      note: note == _absent
          ? this.note
          : note as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VacationPeriod && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    if (note != null) 'note': note,
  };

  factory VacationPeriod.fromJson(Map<String, dynamic> json) => VacationPeriod(
    id: json['_id']?.toString() ?? sharedUuid.v4(),
    name: json['name'] as String,
    startDate: parseDateTime(json['startDate']),
    endDate: parseDateTime(json['endDate']),
    note: json['note'] as String?,
  );

  @override
  String toString() => 'VacationPeriod("$name", $startDate — $endDate)';
}
