import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/single_instance_guard.dart';

SingleInstanceGuard? _instanceGuard;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _instanceGuard = await SingleInstanceGuard.tryAcquire();
  if (SingleInstanceGuard.isSupported && _instanceGuard == null) {
    stderr.writeln('Another instance of Class Activity Manager is already running.');
    exit(0);
  }

  runApp(
    const ProviderScope(
      child: ClassActivityManagerApp(),
    ),
  );
}
