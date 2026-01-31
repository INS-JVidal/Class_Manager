import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Període de vacances específic d'un curs acadèmic (Nadal, Setmana Santa).
class VacationPeriod {
  VacationPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.note,
  });

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
    String? note,
  }) {
    return VacationPeriod(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (note != null) 'note': note,
      };

  factory VacationPeriod.fromJson(Map<String, dynamic> json) => VacationPeriod(
        id: json['_id']?.toString() ?? _uuid.v4(),
        name: json['name'] as String,
        startDate: _parseDateTime(json['startDate']),
        endDate: _parseDateTime(json['endDate']),
        note: json['note'] as String?,
      );

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }
}
