import 'package:mongo_dart/mongo_dart.dart';

import '../../models/daily_note.dart';
import '../datasources/mongodb_datasource.dart';

/// Repository for DailyNote CRUD operations.
class DailyNoteRepository {
  DailyNoteRepository(this._datasource);

  final MongoDbDatasource _datasource;

  DbCollection get _collection => _datasource.collection('daily_notes');

  Future<List<DailyNote>> findAll() async {
    final docs = await _collection.find().toList();
    return docs.map((doc) => DailyNote.fromJson(doc)).toList();
  }

  Future<DailyNote?> findById(String id) async {
    final doc = await _collection.findOne(where.eq('_id', id));
    return doc != null ? DailyNote.fromJson(doc) : null;
  }

  Future<DailyNote> insert(DailyNote note) async {
    await _collection.insertOne(note.toJson());
    return note;
  }

  Future<DailyNote> update(DailyNote note) async {
    await _collection.replaceOne(
      where.eq('_id', note.id),
      note.toJson(),
    );
    return note;
  }

  Future<void> delete(String id) async {
    await _collection.deleteOne(where.eq('_id', id));
  }

  Future<List<DailyNote>> findByGroupAndModule(
      String groupId, String modulId) async {
    final docs = await _collection
        .find(where.eq('groupId', groupId).eq('modulId', modulId))
        .toList();
    return docs.map((doc) => DailyNote.fromJson(doc)).toList();
  }

  Future<List<DailyNote>> findByRaId(String raId) async {
    final docs = await _collection.find(where.eq('raId', raId)).toList();
    return docs.map((doc) => DailyNote.fromJson(doc)).toList();
  }

  Future<DailyNote?> findByGroupRaDate(
      String groupId, String raId, DateTime date) async {
    final dateStr =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final doc = await _collection.findOne(
      where.eq('groupId', groupId).eq('raId', raId).eq('date', dateStr),
    );
    return doc != null ? DailyNote.fromJson(doc) : null;
  }

  Future<List<DailyNote>> findByGroupRa(String groupId, String raId) async {
    final docs = await _collection
        .find(where.eq('groupId', groupId).eq('raId', raId))
        .toList();
    return docs.map((doc) => DailyNote.fromJson(doc)).toList();
  }
}
