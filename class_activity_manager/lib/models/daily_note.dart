import '../core/utils/date_formats.dart';

const _absent = _Absent();

class _Absent {
  const _Absent();
}

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
    this.version = 1,
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

  /// Version for optimistic locking (incremented on each update).
  final int version;

  DailyNote copyWith({
    String? id,
    String? raId,
    String? modulId,
    String? groupId,
    DateTime? date,
    Object? plannedContent = _absent,
    Object? actualContent = _absent,
    Object? notes = _absent,
    bool? completed,
    int? version,
  }) {
    return DailyNote(
      id: id ?? this.id,
      raId: raId ?? this.raId,
      modulId: modulId ?? this.modulId,
      groupId: groupId ?? this.groupId,
      date: date ?? this.date,
      plannedContent: plannedContent == _absent
          ? this.plannedContent
          : plannedContent as String?,
      actualContent: actualContent == _absent
          ? this.actualContent
          : actualContent as String?,
      notes: notes == _absent
          ? this.notes
          : notes as String?,
      completed: completed ?? this.completed,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DailyNote && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
    '_id': id,
    'raId': raId,
    'modulId': modulId,
    'groupId': groupId,
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    if (plannedContent != null) 'plannedContent': plannedContent,
    if (actualContent != null) 'actualContent': actualContent,
    if (notes != null) 'notes': notes,
    'completed': completed,
    'version': version,
  };

  factory DailyNote.fromJson(Map<String, dynamic> json) => DailyNote(
    id: json['_id']?.toString() ?? sharedUuid.v4(),
    raId: json['raId'] as String,
    modulId: json['modulId'] as String,
    groupId: json['groupId'] as String,
    date: parseDateTime(json['date']),
    plannedContent: json['plannedContent'] as String?,
    actualContent: json['actualContent'] as String?,
    notes: json['notes'] as String?,
    completed: json['completed'] as bool? ?? false,
    version: json['version'] as int? ?? 1,
  );

  @override
  String toString() => 'DailyNote($id, ra:$raId, ${date.toIso8601String().substring(0, 10)})';
}
