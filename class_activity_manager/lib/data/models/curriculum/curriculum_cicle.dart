import 'curriculum_modul.dart';

/// Cicle formatiu in the curriculum YAML. Read-only reference.
class CurriculumCicle {
  const CurriculumCicle({
    required this.codi,
    required this.nom,
    this.acronim,
    this.horesTotals,
    this.horesCentre,
    this.horesEmpresa,
    required this.moduls,
  });

  final String codi;
  final String nom;
  final String? acronim;
  final int? horesTotals;
  final int? horesCentre;
  final int? horesEmpresa;
  final List<CurriculumModul> moduls;

  factory CurriculumCicle.fromJson(Map<dynamic, dynamic> json) {
    final modulsList = json['moduls'] as List<dynamic>?;
    final moduls = modulsList
            ?.map((e) => CurriculumModul.fromJson(Map<dynamic, dynamic>.from(e as Map)))
            .toList() ??
        [];
    return CurriculumCicle(
      codi: (json['codi'] as String?) ?? '',
      nom: (json['nom'] as String?) ?? '',
      acronim: json['acronim'] as String?,
      horesTotals: (json['hores_totals'] as num?)?.toInt(),
      horesCentre: (json['hores_centre'] as num?)?.toInt(),
      horesEmpresa: (json['hores_empresa'] as num?)?.toInt(),
      moduls: moduls,
    );
  }
}
