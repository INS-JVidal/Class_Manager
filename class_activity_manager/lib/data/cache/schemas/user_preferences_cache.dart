import 'package:isar/isar.dart';

part 'user_preferences_cache.g.dart';

/// Isar cache schema for UserPreferences entity.
@collection
class UserPreferencesCache {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String languageCode;

  /// Version for optimistic locking.
  int version = 1;

  late DateTime lastModified;
  late bool pendingSync;
}
