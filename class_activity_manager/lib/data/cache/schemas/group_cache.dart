import 'package:isar/isar.dart';

part 'group_cache.g.dart';

/// Isar cache schema for Group entity.
@collection
class GroupCache {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String name;
  String? notes;
  String? academicYearId;
  late List<String> moduleIds;
  String? color;

  late DateTime lastModified;
  late bool pendingSync;
}
