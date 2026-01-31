import 'ra.dart';

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
  });

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

  /// Display string for cycle codes (e.g., "DAM, DAW").
  String get cicleCodesDisplay => cicleCodes.join(', ');

  Modul copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    int? totalHours,
    List<String>? objectives,
    String? officialReference,
    List<RA>? ras,
    List<String>? cicleCodes,
  }) {
    return Modul(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      totalHours: totalHours ?? this.totalHours,
      objectives: objectives ?? this.objectives,
      officialReference: officialReference ?? this.officialReference,
      ras: ras ?? this.ras,
      cicleCodes: cicleCodes ?? this.cicleCodes,
    );
  }
}
