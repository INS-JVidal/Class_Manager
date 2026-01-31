/// Grup d'alumnes (classe): DAW1-A, SMX2-B, etc.
class Group {
  Group({
    required this.id,
    required this.name,
    this.notes,
    this.academicYearId,
    this.moduleIds = const [],
  });

  final String id;
  final String name;
  final String? notes;
  final String? academicYearId;
  /// IDs dels mòduls que s'imparteixen en aquest grup.
  final List<String> moduleIds;

  Group copyWith({
    String? id,
    String? name,
    String? notes,
    String? academicYearId,
    List<String>? moduleIds,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      academicYearId: academicYearId ?? this.academicYearId,
      moduleIds: moduleIds ?? this.moduleIds,
    );
  }
}
