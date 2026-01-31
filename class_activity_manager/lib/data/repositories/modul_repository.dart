import 'package:mongo_dart/mongo_dart.dart';

import '../../models/modul.dart';
import '../datasources/mongodb_datasource.dart';

/// Repository for Modul CRUD operations.
class ModulRepository {
  ModulRepository(this._datasource);

  final MongoDbDatasource _datasource;

  DbCollection get _collection => _datasource.collection('moduls');

  Future<List<Modul>> findAll() async {
    final docs = await _collection.find().toList();
    return docs.map((doc) => Modul.fromJson(doc)).toList();
  }

  Future<Modul?> findById(String id) async {
    final doc = await _collection.findOne(where.eq('_id', id));
    return doc != null ? Modul.fromJson(doc) : null;
  }

  Future<Modul?> findByCode(String code) async {
    final doc = await _collection.findOne(where.eq('code', code));
    return doc != null ? Modul.fromJson(doc) : null;
  }

  Future<Modul> insert(Modul modul) async {
    await _collection.insertOne(modul.toJson());
    return modul;
  }

  Future<Modul> update(Modul modul) async {
    await _collection.replaceOne(
      where.eq('_id', modul.id),
      modul.toJson(),
    );
    return modul;
  }

  Future<void> delete(String id) async {
    await _collection.deleteOne(where.eq('_id', id));
  }

  Future<List<Modul>> findByCicleCodes(List<String> cicleCodes) async {
    if (cicleCodes.isEmpty) return [];
    final docs = await _collection
        .find(where.oneFrom('cicleCodes', cicleCodes))
        .toList();
    return docs.map((doc) => Modul.fromJson(doc)).toList();
  }
}
