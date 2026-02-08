import '../core/utils/date_formats.dart';

const _absent = _Absent();

class _Absent {
  const _Absent();
}

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
  }) : assert(durationHours >= 0, 'durationHours must be non-negative');

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
    Object? description = _absent,
    int? durationHours,
    int? order,
    Object? startDate = _absent,
    Object? endDate = _absent,
  }) {
    return RA(
      id: id ?? this.id,
      number: number ?? this.number,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description == _absent
          ? this.description
          : description as String?,
      durationHours: durationHours ?? this.durationHours,
      order: order ?? this.order,
      startDate: startDate == _absent
          ? this.startDate
          : startDate as DateTime?,
      endDate: endDate == _absent
          ? this.endDate
          : endDate as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RA && id == other.id;

  @override
  int get hashCode => id.hashCode;

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
    id: json['_id']?.toString() ?? sharedUuid.v4(),
    number: json['number'] as int,
    code: json['code'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    durationHours: json['durationHours'] as int,
    order: json['order'] as int? ?? 0,
    startDate: json['startDate'] != null
        ? parseDateTime(json['startDate'])
        : null,
    endDate: json['endDate'] != null ? parseDateTime(json['endDate']) : null,
  );

  @override
  String toString() => 'RA($code, "$title", ${durationHours}h)';
}
