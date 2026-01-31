import 'package:isar/isar.dart';

part 'modul_cache.g.dart';

/// Isar cache schema for Modul entity.
@collection
class ModulCache {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String code;
  late String name;
  String? description;
  late int totalHours;
  late List<String> objectives;
  String? officialReference;

  /// Nested RAs stored as JSON string.
  late String rasJson;
  late List<String> cicleCodes;

  late DateTime lastModified;
  late bool pendingSync;
}
