import '../core/utils/date_formats.dart';

/// User preferences including language setting.
/// There should only be one active UserPreferences document per user/device.
class UserPreferences {
  UserPreferences({
    required this.id,
    this.languageCode = 'ca',
    this.version = 1,
  });

  final String id;

  /// Language code: 'ca' (Catalan) or 'en' (English).
  final String languageCode;

  /// Version for optimistic locking (incremented on each update).
  final int version;

  UserPreferences copyWith({String? id, String? languageCode, int? version}) {
    return UserPreferences(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserPreferences && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
    '_id': id,
    'languageCode': languageCode,
    'version': version,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        id: json['_id']?.toString() ?? sharedUuid.v4(),
        languageCode: json['languageCode'] as String? ?? 'ca',
        version: json['version'] as int? ?? 1,
      );

  /// Create default preferences with a new ID.
  factory UserPreferences.defaults() =>
      UserPreferences(id: sharedUuid.v4(), languageCode: 'ca');

  @override
  String toString() => 'UserPreferences($id, lang:$languageCode)';
}
