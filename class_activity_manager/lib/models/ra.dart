import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Resultat d'Aprenentatge (RA) dins d'un mòdul.
class RA {
  RA({
    required this.id,
    required this.number,
    required this.code,
    required this.title,
    this.description,
    required this.durationHours,
    this.order = 0,
    this.startDate,
    this.endDate,
  });

  final String id;
  final int number;
  final String code;
  final String title;
  final String? description;
  final int durationHours;
  final int order;
  final DateTime? startDate;
  final DateTime? endDate;

  RA copyWith({
    String? id,
    int? number,
    String? code,
    String? title,
    String? description,
    int? durationHours,
    int? order,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return RA(
      id: id ?? this.id,
      number: number ?? this.number,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      durationHours: durationHours ?? this.durationHours,
      order: order ?? this.order,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'number': number,
    'code': code,
    'title': title,
    if (description != null) 'description': description,
    'durationHours': durationHours,
    'order': order,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
  };

  factory RA.fromJson(Map<String, dynamic> json) => RA(
    id: json['_id']?.toString() ?? _uuid.v4(),
    number: json['number'] as int,
    code: json['code'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    durationHours: json['durationHours'] as int,
    order: json['order'] as int? ?? 0,
    startDate: json['startDate'] != null
        ? _parseDateTime(json['startDate'])
        : null,
    endDate: json['endDate'] != null ? _parseDateTime(json['endDate']) : null,
  );

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }
}
