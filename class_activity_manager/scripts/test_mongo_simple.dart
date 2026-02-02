import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final envContent = File('lib/.env').readAsStringSync();
  final match = RegExp(r'MONGO_URI=(.+)').firstMatch(envContent);
  if (match == null) { print('MONGO_URI not found'); exit(1); }

  final uri = match.group(1)!.trim();
  final masked = uri.replaceAllMapped(RegExp(r':([^:@]+)@'), (m) => ':****@');
  print('URI: $masked');
  print('Connecting...');

  try {
    final db = await Db.create(uri);
    await db.open();
    print('SUCCESS!');
    print('Collections: ${await db.getCollectionNames()}');
    await db.close();
  } catch (e) {
    print('FAILED: $e');
    exit(1);
  }
}
