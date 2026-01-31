import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Festiu recurrent (mateixa data cada any): Nadal, Diada, etc.
class RecurringHoliday {
  RecurringHoliday({
    required this.id,
    required this.name,
    required this.month,
    required this.day,
    this.isEnabled = true,
    this.version = 1,
  });

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
        id: json['_id']?.toString() ?? _uuid.v4(),
        name: json['name'] as String,
        month: json['month'] as int,
        day: json['day'] as int,
        isEnabled: json['isEnabled'] as bool? ?? true,
        version: json['version'] as int? ?? 1,
      );
}
