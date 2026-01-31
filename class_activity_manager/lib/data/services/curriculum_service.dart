import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../models/curriculum/curriculum.dart';

const _assetPath = 'assets/curriculum-informatica.yaml';

/// Loads and parses curriculum-informatica.yaml. Returns read-only curriculum data.
class CurriculumService {
  CurriculumService();

  List<CurriculumCicle>? _cached;

  /// Load curriculum from asset. Caches result.
  Future<List<CurriculumCicle>> loadCicles() async {
    if (_cached != null) return _cached!;
    final content = await rootBundle.loadString(_assetPath);
    final doc = loadYaml(content) as Map<dynamic, dynamic>?;
    if (doc == null) return [];
    final ciclesList = doc['cicles'] as List<dynamic>?;
    if (ciclesList == null) return [];
    _cached = ciclesList
        .map((e) => CurriculumCicle.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    return _cached!;
  }

  /// Clear cache (e.g. after asset change).
  void clearCache() {
    _cached = null;
  }
}

final curriculumServiceProvider = Provider<CurriculumService>((ref) => CurriculumService());

final curriculumCiclesProvider = FutureProvider<List<CurriculumCicle>>((ref) async {
  final service = ref.watch(curriculumServiceProvider);
  return service.loadCicles();
});
