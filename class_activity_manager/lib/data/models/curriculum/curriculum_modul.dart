import 'curriculum_uf.dart';

/// Mòdul professional in the curriculum YAML. Read-only reference.
class CurriculumModul {
  const CurriculumModul({
    required this.codi,
    this.codiBod,
    required this.nom,
    required this.hores,
    this.curs,
    required this.ufs,
  });

  final String codi;
  final String? codiBod;
  final String nom;
  final int hores;
  final int? curs;
  final List<CurriculumUF> ufs;

  factory CurriculumModul.fromJson(Map<dynamic, dynamic> json) {
    final ufsList = json['ufs'] as List<dynamic>?;
    final ufs =
        ufsList
            ?.map(
              (e) =>
                  CurriculumUF.fromJson(Map<dynamic, dynamic>.from(e as Map)),
            )
            .toList() ??
        [];
    return CurriculumModul(
      codi: (json['codi'] as String?) ?? '',
      codiBod: json['codi_bod'] as String?,
      nom: (json['nom'] as String?) ?? '',
      hores: (json['hores'] as num?)?.toInt() ?? 0,
      curs: (json['curs'] as num?)?.toInt(),
      ufs: ufs,
    );
  }
}
