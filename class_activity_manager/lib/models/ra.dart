import 'criteri_avaluacio.dart';

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
    this.criterisAvaluacio = const [],
    this.startDate,
    this.endDate,
  });

  final String id;
  final int number;
  final String code;
  final String title;
  final String? description;
  final int durationHours;
  final int order;
  final List<CriteriAvaluacio> criterisAvaluacio;
  final DateTime? startDate;
  final DateTime? endDate;

  RA copyWith({
    String? id,
    int? number,
    String? code,
    String? title,
    String? description,
    int? durationHours,
    int? order,
    List<CriteriAvaluacio>? criterisAvaluacio,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return RA(
      id: id ?? this.id,
      number: number ?? this.number,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      durationHours: durationHours ?? this.durationHours,
      order: order ?? this.order,
      criterisAvaluacio: criterisAvaluacio ?? this.criterisAvaluacio,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
