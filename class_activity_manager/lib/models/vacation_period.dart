/// Període de vacances específic d'un curs acadèmic (Nadal, Setmana Santa).
class VacationPeriod {
  VacationPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.note,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? note;

  VacationPeriod copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? note,
  }) {
    return VacationPeriod(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      note: note ?? this.note,
    );
  }
}
