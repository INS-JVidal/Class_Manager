/// Criteri d'avaluació (CA) dins d'un RA.
class CriteriAvaluacio {
  CriteriAvaluacio({
    required this.id,
    required this.code,
    required this.description,
    this.order = 0,
  });

  final String id;
  final String code;
  final String description;
  final int order;

  CriteriAvaluacio copyWith({
    String? id,
    String? code,
    String? description,
    int? order,
  }) {
    return CriteriAvaluacio(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      order: order ?? this.order,
    );
  }
}
