import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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

  Map<String, dynamic> toJson() => {
        '_id': id,
        'code': code,
        'description': description,
        'order': order,
      };

  factory CriteriAvaluacio.fromJson(Map<String, dynamic> json) =>
      CriteriAvaluacio(
        id: json['_id']?.toString() ?? _uuid.v4(),
        code: json['code'] as String,
        description: json['description'] as String,
        order: json['order'] as int? ?? 0,
      );
}
