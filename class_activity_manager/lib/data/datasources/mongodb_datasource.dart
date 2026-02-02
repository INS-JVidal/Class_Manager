import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// Connection mode for MongoDB.
enum MongoConnectionMode { local, online }

/// Connection info returned after successful connection.
class MongoConnectionInfo {
  final MongoConnectionMode mode;
  final String maskedUri;

  const MongoConnectionInfo({required this.mode, required this.maskedUri});

  bool get isLocal => mode == MongoConnectionMode.local;
  bool get isOnline => mode == MongoConnectionMode.online;
}

/// MongoDB datasource for connection management.
class MongoDbDatasource {
  Db? _db;
  MongoConnectionInfo? _connectionInfo;

  bool get isConnected => _db?.isConnected ?? false;

  /// Connection info (available after successful connect).
  MongoConnectionInfo? get connectionInfo => _connectionInfo;

  /// Connects to MongoDB and returns connection info.
  Future<MongoConnectionInfo> connect() async {
    if (_db != null && _db!.isConnected && _connectionInfo != null) {
      return _connectionInfo!;
    }

    final uri = dotenv.env['MONGO_URI'];
    if (uri == null || uri.isEmpty) {
      throw StateError('MONGO_URI not found in environment');
    }

    _db = await Db.create(uri);
    await _db!.open();

    // Determine connection mode and create masked URI
    _connectionInfo = _parseConnectionInfo(uri);
    return _connectionInfo!;
  }

  /// Parses URI to determine mode and create masked version.
  MongoConnectionInfo _parseConnectionInfo(String uri) {
    // Check if local connection
    final isLocal =
        uri.contains('localhost') ||
        uri.contains('127.0.0.1') ||
        uri.contains('0.0.0.0');

    // Mask password in URI for display
    final maskedUri = uri.replaceAllMapped(
      RegExp(r'://([^:]+):([^@]+)@'),
      (m) => '://${m[1]}:****@',
    );

    return MongoConnectionInfo(
      mode: isLocal ? MongoConnectionMode.local : MongoConnectionMode.online,
      maskedUri: maskedUri,
    );
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
