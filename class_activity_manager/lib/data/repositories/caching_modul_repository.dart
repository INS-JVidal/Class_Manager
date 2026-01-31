import 'dart:convert';

import 'package:isar/isar.dart';

import '../../models/modul.dart';
import '../../models/ra.dart';
import '../cache/schemas/modul_cache.dart';
import '../cache/schemas/sync_operation.dart';
import '../cache/sync_queue.dart';
import '../datasources/local_datasource.dart';

/// Caching repository for Modul with local-first persistence.
class CachingModulRepository {
  CachingModulRepository(this._local, this._queue);

  final LocalDatasource _local;
  final SyncQueue _queue;

  IsarCollection<ModulCache> get _collection => _local.db.modulCaches;

  Future<List<Modul>> findAll() async {
    final cached = await _collection.where().findAll();
    return cached.map(_toModul).toList();
  }

  Future<Modul?> findById(String id) async {
    final cached = await _collection.filter().idEqualTo(id).findFirst();
    return cached != null ? _toModul(cached) : null;
  }

  Future<Modul?> findByCode(String code) async {
    final cached = await _collection.filter().codeEqualTo(code).findFirst();
    return cached != null ? _toModul(cached) : null;
  }

  Future<Modul> insert(Modul modul) async {
    await _local.db.writeTxn(() async {
      await _collection.put(_toCache(modul));
    });

    await _queue.enqueue(
      entityType: 'modul',
      entityId: modul.id,
      operation: SyncOperationType.insert,
      payload: modul.toJson(),
    );

    return modul;
  }

  Future<Modul> update(Modul modul) async {
    final existing = await _collection.filter().idEqualTo(modul.id).findFirst();
    final cache = _toCache(modul);
    if (existing != null) {
      cache.isarId = existing.isarId;
    }

    await _local.db.writeTxn(() async {
      await _collection.put(cache);
    });

    await _queue.enqueue(
      entityType: 'modul',
      entityId: modul.id,
      operation: SyncOperationType.update,
      payload: modul.toJson(),
    );

    return modul;
  }

  Future<void> delete(String id) async {
    final existing = await _collection.filter().idEqualTo(id).findFirst();

    if (existing != null) {
      await _local.db.writeTxn(() async {
        await _collection.delete(existing.isarId);
      });
    }

    await _queue.enqueue(
      entityType: 'modul',
      entityId: id,
      operation: SyncOperationType.delete,
      payload: {'_id': id},
    );
  }

  Future<List<Modul>> findByCicleCodes(List<String> cicleCodes) async {
    if (cicleCodes.isEmpty) return [];
    final all = await findAll();
    return all
        .where((m) => m.cicleCodes.any((c) => cicleCodes.contains(c)))
        .toList();
  }

  Future<void> syncFromRemote(List<Modul> moduls) async {
    await _local.db.writeTxn(() async {
      await _collection.clear();
      for (final modul in moduls) {
        await _collection.put(_toCache(modul, pendingSync: false));
      }
    });
  }

  Modul _toModul(ModulCache cache) {
    return Modul(
      id: cache.id,
      code: cache.code,
      name: cache.name,
      description: cache.description,
      totalHours: cache.totalHours,
      objectives: cache.objectives,
      officialReference: cache.officialReference,
      ras: _decodeRas(cache.rasJson),
      cicleCodes: cache.cicleCodes,
      version: cache.version,
    );
  }

  ModulCache _toCache(Modul modul, {bool pendingSync = true}) {
    return ModulCache()
      ..id = modul.id
      ..code = modul.code
      ..name = modul.name
      ..description = modul.description
      ..totalHours = modul.totalHours
      ..objectives = modul.objectives
      ..officialReference = modul.officialReference
      ..rasJson = jsonEncode(modul.ras.map((r) => r.toJson()).toList())
      ..cicleCodes = modul.cicleCodes
      ..version = modul.version
      ..lastModified = DateTime.now()
      ..pendingSync = pendingSync;
  }

  List<RA> _decodeRas(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((r) => RA.fromJson(r as Map<String, dynamic>)).toList();
  }
}
