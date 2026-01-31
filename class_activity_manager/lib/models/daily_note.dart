import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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
      };

  factory DailyNote.fromJson(Map<String, dynamic> json) => DailyNote(
        id: json['_id']?.toString() ?? _uuid.v4(),
        raId: json['raId'] as String,
        modulId: json['modulId'] as String,
        groupId: json['groupId'] as String,
        date: _parseDateTime(json['date']),
        plannedContent: json['plannedContent'] as String?,
        actualContent: json['actualContent'] as String?,
        notes: json['notes'] as String?,
        completed: json['completed'] as bool? ?? false,
      );

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }
}
