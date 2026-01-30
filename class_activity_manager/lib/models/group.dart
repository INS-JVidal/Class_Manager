/// Grup d'alumnes (classe): DAW1-A, SMX2-B, etc.
class Group {
  Group({
    required this.id,
    required this.name,
    this.notes,
    this.academicYearId,
  });

  final String id;
  final String name;
  final String? notes;
  final String? academicYearId;

  Group copyWith({
    String? id,
    String? name,
    String? notes,
    String? academicYearId,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      academicYearId: academicYearId ?? this.academicYearId,
    );
  }
}
