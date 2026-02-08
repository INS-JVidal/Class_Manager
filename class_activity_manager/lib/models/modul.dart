import '../core/utils/date_formats.dart';
import 'ra.dart';

const _absent = _Absent();

class _Absent {
  const _Absent();
}

/// Mòdul professional (assignatura): MP06, etc.
class Modul {
  Modul({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.totalHours,
    this.objectives = const [],
    this.officialReference,
    this.ras = const [],
    this.cicleCodes = const [],
    this.version = 1,
  }) : assert(totalHours >= 0, 'totalHours must be non-negative');

  final String id;
  final String code;
  final String name;
  final String? description;
  final int totalHours;
  final List<String> objectives;
  final String? officialReference;
  final List<RA> ras;

  /// Codis dels cicles on s'imparteix el mòdul (e.g. ICC0, ICB0).
  final List<String> cicleCodes;

  /// Version for optimistic locking (incremented on each update).
  final int version;

  /// Display string for cycle codes (e.g., "DAM, DAW").
  String get cicleCodesDisplay => cicleCodes.join(', ');

  Modul copyWith({
    String? id,
    String? code,
    String? name,
    Object? description = _absent,
    int? totalHours,
    List<String>? objectives,
    Object? officialReference = _absent,
    List<RA>? ras,
    List<String>? cicleCodes,
    int? version,
  }) {
    return Modul(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description == _absent
          ? this.description
          : description as String?,
      totalHours: totalHours ?? this.totalHours,
      objectives: objectives ?? this.objectives,
      officialReference: officialReference == _absent
          ? this.officialReference
          : officialReference as String?,
      ras: ras ?? this.ras,
      cicleCodes: cicleCodes ?? this.cicleCodes,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'code': code,
    'name': name,
    if (description != null) 'description': description,
    'totalHours': totalHours,
    'objectives': objectives,
    if (officialReference != null) 'officialReference': officialReference,
    'ras': ras.map((ra) => ra.toJson()).toList(),
    'cicleCodes': cicleCodes,
    'version': version,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Modul && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory Modul.fromJson(Map<String, dynamic> json) => Modul(
    id: json['_id']?.toString() ?? sharedUuid.v4(),
    code: json['code'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    totalHours: json['totalHours'] as int,
    objectives: (json['objectives'] as List<dynamic>?)?.cast<String>() ?? [],
    officialReference: json['officialReference'] as String?,
    ras:
        (json['ras'] as List<dynamic>?)
            ?.map((e) => RA.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    cicleCodes: (json['cicleCodes'] as List<dynamic>?)?.cast<String>() ?? [],
    version: json['version'] as int? ?? 1,
  );

  @override
  String toString() => 'Modul($code, "$name", ${ras.length} RAs)';
}
