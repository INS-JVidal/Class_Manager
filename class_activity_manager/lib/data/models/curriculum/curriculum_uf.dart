/// UF (Unitat Formativa) = RA in the curriculum YAML. Read-only reference.
class CurriculumUF {
  const CurriculumUF({
    required this.codi,
    required this.nom,
    required this.hores,
  });

  final String codi;
  final String nom;
  final int hores;

  factory CurriculumUF.fromJson(Map<dynamic, dynamic> json) {
    return CurriculumUF(
      codi: (json['codi'] as String?) ?? '',
      nom: (json['nom'] as String?) ?? '',
      hores: (json['hores'] as num?)?.toInt() ?? 0,
    );
  }
}
