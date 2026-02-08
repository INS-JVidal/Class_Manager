import '../core/utils/date_formats.dart';

/// Festiu recurrent (mateixa data cada any): Nadal, Diada, etc.
class RecurringHoliday {
  RecurringHoliday({
    required this.id,
    required this.name,
    required this.month,
    required this.day,
    this.isEnabled = true,
    this.version = 1,
  }) : assert(month >= 1 && month <= 12, 'month must be 1-12'),
       assert(day >= 1 && day <= 31, 'day must be 1-31');

  final String id;
  final String name;
  final int month; // 1-12
  final int day; // 1-31
  final bool isEnabled;

  /// Version for optimistic locking (incremented on each update).
  final int version;

  RecurringHoliday copyWith({
    String? id,
    String? name,
    int? month,
    int? day,
    bool? isEnabled,
    int? version,
  }) {
    return RecurringHoliday(
      id: id ?? this.id,
      name: name ?? this.name,
      month: month ?? this.month,
      day: day ?? this.day,
      isEnabled: isEnabled ?? this.isEnabled,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RecurringHoliday && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'month': month,
    'day': day,
    'isEnabled': isEnabled,
    'version': version,
  };

  factory RecurringHoliday.fromJson(Map<String, dynamic> json) =>
      RecurringHoliday(
        id: json['_id']?.toString() ?? sharedUuid.v4(),
        name: json['name'] as String,
        month: json['month'] as int,
        day: json['day'] as int,
        isEnabled: json['isEnabled'] as bool? ?? true,
        version: json['version'] as int? ?? 1,
      );

  @override
  String toString() => 'RecurringHoliday("$name", $day/$month)';
}
