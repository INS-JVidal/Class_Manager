import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Grup d'alumnes (classe): DAW1-A, SMX2-B, etc.
class Group {
  Group({
    required this.id,
    required this.name,
    this.notes,
    this.academicYearId,
    this.moduleIds = const [],
    this.color,
  });

  final String id;
  final String name;
  final String? notes;
  final String? academicYearId;

  /// IDs dels mòduls que s'imparteixen en aquest grup.
  final List<String> moduleIds;

  /// Color del grup en format hexadecimal (p.ex. "#4CAF50").
  final String? color;

  Group copyWith({
    String? id,
    String? name,
    String? notes,
    String? academicYearId,
    List<String>? moduleIds,
    String? color,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      academicYearId: academicYearId ?? this.academicYearId,
      moduleIds: moduleIds ?? this.moduleIds,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    if (notes != null) 'notes': notes,
    if (academicYearId != null) 'academicYearId': academicYearId,
    'moduleIds': moduleIds,
    if (color != null) 'color': color,
  };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['_id']?.toString() ?? _uuid.v4(),
    name: json['name'] as String,
    notes: json['notes'] as String?,
    academicYearId: json['academicYearId']?.toString(),
    moduleIds:
        (json['moduleIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    color: json['color'] as String?,
  );
}
