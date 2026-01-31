import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// MongoDB datasource for connection management.
class MongoDbDatasource {
  Db? _db;

  bool get isConnected => _db?.isConnected ?? false;

  Future<void> connect() async {
    if (_db != null && _db!.isConnected) return;

    final uri = dotenv.env['MONGO_URI'];
    if (uri == null || uri.isEmpty) {
      throw StateError('MONGO_URI not found in environment');
    }

    _db = await Db.create(uri);
    await _db!.open();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  DbCollection collection(String name) {
    if (_db == null || !_db!.isConnected) {
      throw StateError('Database not connected. Call connect() first.');
    }
    return _db!.collection(name);
  }
}
