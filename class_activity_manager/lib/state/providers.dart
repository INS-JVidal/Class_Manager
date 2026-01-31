import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/database_service.dart';

/// Provider for the database service.
/// Returns null if database is not connected.
final databaseServiceProvider = Provider<DatabaseService?>((ref) {
  // Returns null by default - must be overridden in main.dart when DB is connected
  return null;
});
