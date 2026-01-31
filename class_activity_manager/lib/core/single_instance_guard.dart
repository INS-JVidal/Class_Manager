import 'dart:io';

import 'package:flutter/foundation.dart';

class SingleInstanceGuard {
  SingleInstanceGuard._(this._fileHandle);

  final RandomAccessFile _fileHandle;

  static bool get isSupported =>
      !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  static Future<SingleInstanceGuard?> tryAcquire({
    String lockFileName = '.class_activity_manager.lock',
  }) async {
    if (!isSupported) {
      return null;
    }

    final lockDirectory = _resolveLockDirectory();
    if (lockDirectory == null) {
      return null;
    }

    lockDirectory.createSync(recursive: true);
    final lockPath = _joinPath(lockDirectory.path, lockFileName);
    final lockFile = File(lockPath);

    try {
      final handle = lockFile.openSync(mode: FileMode.write);
      handle.lockSync(FileLock.exclusive);
      return SingleInstanceGuard._(handle);
    } on FileSystemException {
      return null;
    }
  }

  void release() {
    try {
      _fileHandle.unlockSync();
    } on FileSystemException {
      // Ignore unlock failures during shutdown.
    } finally {
      try {
        _fileHandle.closeSync();
      } on FileSystemException {
        // Ignore close failures during shutdown.
      }
    }
  }

  static Directory? _resolveLockDirectory() {
    final env = Platform.environment;

    if (Platform.isWindows) {
      final base = env['APPDATA'] ?? env['USERPROFILE'];
      if (base == null) {
        return null;
      }
      return Directory(_joinPath(base, 'ClassActivityManager'));
    }

    final home = env['HOME'];
    if (home == null) {
      return null;
    }

    if (Platform.isMacOS) {
      return Directory(
        _joinPath(home, _joinPath('Library', 'Application Support')),
      ).child('ClassActivityManager');
    }

    return Directory(
      _joinPath(home, _joinPath('.cache', 'class_activity_manager')),
    );
  }

  static String _joinPath(String base, String child) {
    final separator = Platform.pathSeparator;
    if (base.endsWith(separator)) {
      return '$base$child';
    }
    return '$base$separator$child';
  }
}

extension on Directory {
  Directory child(String name) =>
      Directory(SingleInstanceGuard._joinPath(path, name));
}
