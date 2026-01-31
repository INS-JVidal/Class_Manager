import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/audit/audit_logger.dart';
import 'core/audit/file_audit_logger.dart';
import 'core/single_instance_guard.dart';
import 'data/cache/sync_queue.dart';
import 'data/datasources/local_datasource.dart';
import 'data/datasources/mongodb_datasource.dart';
import 'data/repositories/caching_user_preferences_repository.dart';
import 'data/services/cache_service.dart';
import 'data/services/database_service.dart';
import 'state/app_state.dart';
import 'state/providers.dart';

SingleInstanceGuard? _instanceGuard;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _instanceGuard = await SingleInstanceGuard.tryAcquire();
  if (SingleInstanceGuard.isSupported && _instanceGuard == null) {
    stderr.writeln(
      'Another instance of Class Activity Manager is already running.',
    );
    exit(0);
  }

  // Load environment variables
  await dotenv.load(fileName: 'lib/.env');

  // 1. Initialize local storage FIRST (always available)
  final localDatasource = LocalDatasource();
  await localDatasource.initialize();
  stderr.writeln('Local cache initialized');

  // 2. Try MongoDB connection (optional)
  final mongoDatasource = MongoDbDatasource();
  DatabaseService? databaseService;
  try {
    await mongoDatasource.connect();
    databaseService = DatabaseService(mongoDatasource);
    stderr.writeln('Connected to MongoDB');
  } catch (e) {
    stderr.writeln('Starting in offline mode: $e');
  }

  // 3. Create sync infrastructure
  final syncQueue = SyncQueue(localDatasource);
  final cacheService = CacheService(
    localDatasource,
    mongoDatasource,
    syncQueue,
  );
  await cacheService.initialize();

  // Audit log to file on Linux (XDG state directory)
  AuditLogger? auditLogger;
  final logDir = resolveAuditLogDirectory();
  if (logDir != null) {
    auditLogger = FileAuditLogger(logDir);
    stderr.writeln('Audit log directory: $logDir');
  }

  // Load saved locale preference before runApp
  Locale savedLocale = const Locale('ca');
  try {
    final prefsRepo = CachingUserPreferencesRepository(localDatasource, syncQueue);
    final prefs = await prefsRepo.findActive();
    if (prefs != null) {
      savedLocale = Locale(prefs.languageCode);
      stderr.writeln('Loaded locale preference: ${prefs.languageCode}');
    }
  } catch (e) {
    stderr.writeln('Could not load locale preference: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        localDatasourceProvider.overrideWithValue(localDatasource),
        databaseServiceProvider.overrideWithValue(databaseService),
        syncQueueProvider.overrideWithValue(syncQueue),
        cacheServiceProvider.overrideWithValue(cacheService),
        localeProvider.overrideWith((ref) => savedLocale),
        appStateProvider.overrideWith(
          (ref) => AppStateNotifier(
            ref.watch(databaseServiceProvider),
            ref.watch(cacheServiceProvider),
            auditLogger,
          ),
        ),
      ],
      child: const _AppWithDatabaseInit(),
    ),
  );
}

/// Wrapper widget that initializes database data on startup.
class _AppWithDatabaseInit extends ConsumerStatefulWidget {
  const _AppWithDatabaseInit();

  @override
  ConsumerState<_AppWithDatabaseInit> createState() =>
      _AppWithDatabaseInitState();
}

class _AppWithDatabaseInitState extends ConsumerState<_AppWithDatabaseInit> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Delay initialization until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      await ref.read(appStateProvider.notifier).loadFromDatabase();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      stderr.writeln('Failed to load data from database: $e');
      if (mounted) {
        setState(() {
          _initialized = true;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Carregant dades...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      // Show error but still allow app to run (in offline mode)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error de connexió: $_error'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }

    return const ClassActivityManagerApp();
  }
}
