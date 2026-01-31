import 'package:mongo_dart/mongo_dart.dart';

import '../../models/academic_year.dart';
import '../datasources/mongodb_datasource.dart';

/// Repository for AcademicYear CRUD operations.
class AcademicYearRepository {
  AcademicYearRepository(this._datasource);

  final MongoDbDatasource _datasource;

  DbCollection get _collection => _datasource.collection('academic_years');

  Future<List<AcademicYear>> findAll() async {
    final docs = await _collection.find().toList();
    return docs.map((doc) => AcademicYear.fromJson(doc)).toList();
  }

  Future<AcademicYear?> findById(String id) async {
    final doc = await _collection.findOne(where.eq('_id', id));
    return doc != null ? AcademicYear.fromJson(doc) : null;
  }

  Future<AcademicYear> insert(AcademicYear year) async {
    await _collection.insertOne(year.toJson());
    return year;
  }

  Future<AcademicYear> update(AcademicYear year) async {
    await _collection.replaceOne(where.eq('_id', year.id), year.toJson());
    return year;
  }

  Future<void> delete(String id) async {
    await _collection.deleteOne(where.eq('_id', id));
  }

  Future<AcademicYear?> findActive() async {
    final doc = await _collection.findOne(where.eq('isActive', true));
    return doc != null ? AcademicYear.fromJson(doc) : null;
  }

  /// Deactivate all academic years except the given one.
  Future<void> setActiveYear(String yearId) async {
    // Deactivate all
    await _collection.updateMany(
      where.ne('_id', yearId),
      ModifierBuilder().set('isActive', false),
    );
    // Activate the specified one
    await _collection.updateOne(
      where.eq('_id', yearId),
      ModifierBuilder().set('isActive', true),
    );
  }
}
