/// Nota diària per una sessió (RA + data + grup).
class DailyNote {
  DailyNote({
    required this.id,
    required this.raId,
    required this.modulId,
    required this.groupId,
    required this.date,
    this.plannedContent,
    this.actualContent,
    this.notes,
    this.completed = false,
  });

  final String id;
  final String raId;
  final String modulId;
  final String groupId;
  final DateTime date;
  /// Contingut planificat per a la sessió.
  final String? plannedContent;
  /// Contingut realment impartit.
  final String? actualContent;
  /// Observacions addicionals.
  final String? notes;
  final bool completed;

  DailyNote copyWith({
    String? id,
    String? raId,
    String? modulId,
    String? groupId,
    DateTime? date,
    String? plannedContent,
    String? actualContent,
    String? notes,
    bool? completed,
  }) {
    return DailyNote(
      id: id ?? this.id,
      raId: raId ?? this.raId,
      modulId: modulId ?? this.modulId,
      groupId: groupId ?? this.groupId,
      date: date ?? this.date,
      plannedContent: plannedContent ?? this.plannedContent,
      actualContent: actualContent ?? this.actualContent,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }
}
