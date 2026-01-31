import 'package:mongo_dart/mongo_dart.dart' show DbCollection, where;

import '../../models/group.dart';
import '../datasources/mongodb_datasource.dart';

/// Repository for Group CRUD operations.
class GroupRepository {
  GroupRepository(this._datasource);

  final MongoDbDatasource _datasource;

  DbCollection get _collection => _datasource.collection('groups');

  Future<List<Group>> findAll() async {
    final docs = await _collection.find().toList();
    return docs.map((doc) => Group.fromJson(doc)).toList();
  }

  Future<Group?> findById(String id) async {
    final doc = await _collection.findOne(where.eq('_id', id));
    return doc != null ? Group.fromJson(doc) : null;
  }

  Future<Group> insert(Group group) async {
    await _collection.insertOne(group.toJson());
    return group;
  }

  Future<Group> update(Group group) async {
    await _collection.replaceOne(where.eq('_id', group.id), group.toJson());
    return group;
  }

  Future<void> delete(String id) async {
    await _collection.deleteOne(where.eq('_id', id));
  }

  Future<List<Group>> findByAcademicYear(String academicYearId) async {
    final docs = await _collection
        .find(where.eq('academicYearId', academicYearId))
        .toList();
    return docs.map((doc) => Group.fromJson(doc)).toList();
  }
}
