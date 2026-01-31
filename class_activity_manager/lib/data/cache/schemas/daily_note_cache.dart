import 'package:isar/isar.dart';

part 'daily_note_cache.g.dart';

/// Isar cache schema for DailyNote entity.
@collection
class DailyNoteCache {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  @Index()
  late String raId;

  late String modulId;

  @Index()
  late String groupId;

  @Index()
  late DateTime date;

  String? plannedContent;
  String? actualContent;
  String? notes;
  late bool completed;

  late DateTime lastModified;
  late bool pendingSync;
}
