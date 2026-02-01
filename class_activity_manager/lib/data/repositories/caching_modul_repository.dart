import 'dart:convert';

import 'package:isar/isar.dart';

import '../../models/modul.dart';
import '../../models/ra.dart';
import '../cache/schemas/modul_cache.dart';
import 'base_caching_repository.dart';

/// Caching repository for Modul with local-first persistence.
///
/// Extends [BaseCachingRepository] to inherit common CRUD operations
/// with automatic sync queue management.
class CachingModulRepository
    extends BaseCachingRepository<Modul, ModulCache> {
  CachingModulRepository(super.local, super.queue);

  @override
  String get entityType => 'modul';

  @override
  IsarCollection<ModulCache> get collection => local.db.modulCaches;

  @override
  Future<ModulCache?> findCacheById(String id) async {
    return collection.filter().idEqualTo(id).findFirst();
  }

  @override
  Id getIsarId(ModulCache cache) => cache.isarId;

  @override
  void setIsarId(ModulCache cache, Id isarId) => cache.isarId = isarId;

  @override
  void preserveVersion(ModulCache cache, ModulCache existing) {
    cache.version = existing.version;
  }

  @override
  Map<String, dynamic> toJson(Modul entity) => entity.toJson();

  @override
  String getId(Modul entity) => entity.id;

  @override
  Modul toEntity(ModulCache cache) {
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

  @override
  ModulCache toCache(Modul modul, {bool pendingSync = true}) {
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

  // --- Entity-specific queries ---

  Future<Modul?> findByCode(String code) async {
    final cached = await collection.filter().codeEqualTo(code).findFirst();
    return cached != null ? toEntity(cached) : null;
  }

  Future<List<Modul>> findByCicleCodes(List<String> cicleCodes) async {
    if (cicleCodes.isEmpty) return [];
    final all = await findAll();
    return all
        .where((m) => m.cicleCodes.any((c) => cicleCodes.contains(c)))
        .toList();
  }

  // --- Private helpers ---

  List<RA> _decodeRas(String json) {
    if (json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List<dynamic>) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((r) => RA.fromJson(r))
          .toList();
    } on FormatException {
      // Corrupted cache data - return empty list rather than crash
      return [];
    }
  }
}
