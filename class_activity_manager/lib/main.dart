import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/single_instance_guard.dart';
import 'data/datasources/mongodb_datasource.dart';
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

  // Initialize MongoDB connection
  final datasource = MongoDbDatasource();
  DatabaseService? databaseService;
  try {
    await datasource.connect();
    databaseService = DatabaseService(datasource);
    stderr.writeln('Connected to MongoDB');
  } catch (e) {
    stderr.writeln('Failed to connect to MongoDB: $e');
    stderr.writeln('App will start without database persistence.');
  }

  runApp(
    ProviderScope(
      overrides: [databaseServiceProvider.overrideWithValue(databaseService)],
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
