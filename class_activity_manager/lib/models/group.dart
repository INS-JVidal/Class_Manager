import '../core/utils/date_formats.dart';

const _absent = _Absent();

class _Absent {
  const _Absent();
}

/// Grup d'alumnes (classe): DAW1-A, SMX2-B, etc.
class Group {
  Group({
    required this.id,
    required this.name,
    this.notes,
    this.academicYearId,
    this.moduleIds = const [],
    this.color,
    this.version = 1,
  });

  final String id;
  final String name;
  final String? notes;
  final String? academicYearId;

  /// IDs dels mòduls que s'imparteixen en aquest grup.
  final List<String> moduleIds;

  /// Color del grup en format hexadecimal (p.ex. "#4CAF50").
  final String? color;

  /// Version for optimistic locking (incremented on each update).
  final int version;

  Group copyWith({
    String? id,
    String? name,
    Object? notes = _absent,
    Object? academicYearId = _absent,
    List<String>? moduleIds,
    Object? color = _absent,
    int? version,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes == _absent
          ? this.notes
          : notes as String?,
      academicYearId: academicYearId == _absent
          ? this.academicYearId
          : academicYearId as String?,
      moduleIds: moduleIds ?? this.moduleIds,
      color: color == _absent
          ? this.color
          : color as String?,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Group && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    if (notes != null) 'notes': notes,
    if (academicYearId != null) 'academicYearId': academicYearId,
    'moduleIds': moduleIds,
    if (color != null) 'color': color,
    'version': version,
  };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['_id']?.toString() ?? sharedUuid.v4(),
    name: json['name'] as String,
    notes: json['notes'] as String?,
    academicYearId: json['academicYearId']?.toString(),
    moduleIds:
        (json['moduleIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    color: json['color'] as String?,
    version: json['version'] as int? ?? 1,
  );

  @override
  String toString() => 'Group($id, "$name")';
}
