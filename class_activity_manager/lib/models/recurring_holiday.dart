/// Festiu recurrent (mateixa data cada any): Nadal, Diada, etc.
class RecurringHoliday {
  RecurringHoliday({
    required this.id,
    required this.name,
    required this.month,
    required this.day,
    this.isEnabled = true,
  });

  final String id;
  final String name;
  final int month; // 1-12
  final int day;   // 1-31
  final bool isEnabled;

  RecurringHoliday copyWith({
    String? id,
    String? name,
    int? month,
    int? day,
    bool? isEnabled,
  }) {
    return RecurringHoliday(
      id: id ?? this.id,
      name: name ?? this.name,
      month: month ?? this.month,
      day: day ?? this.day,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
