import 'dart:convert';

import '../../features/projects/models/project_decision.dart';
import 'local_storage_service.dart';

/// Offline cache for project decisions/timeline using Hive.
///
/// Allows the Project Memory Timeline to render immediately from cached
/// entries while a background network sync updates the view.
class OfflineDecisionsCache {
  /// Returns the box key for a given project's decisions.
  static String _keyFor(String projectId) => 'decisions_$projectId';

  /// Stores a list of [ProjectDecision] records for a specific project.
  static Future<void> saveDecisions(String projectId, List<ProjectDecision> decisions) async {
    final jsonList = decisions.map((d) => jsonEncode(d.toJson())).toList();
    await LocalStorageService.decisionsBox.put(_keyFor(projectId), jsonEncode(jsonList));
  }

  /// Loads cached decisions for [projectId]. Returns an empty list if none.
  static List<ProjectDecision> loadDecisions(String projectId) {
    final raw = LocalStorageService.decisionsBox.get(_keyFor(projectId));
    if (raw == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList
          .map((item) =>
              ProjectDecision.fromJson(jsonDecode(item as String) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Appends a single decision to the local cache for [projectId].
  ///
  /// Used for optimistic local writes before the server confirms.
  static Future<void> appendDecision(String projectId, ProjectDecision decision) async {
    final existing = loadDecisions(projectId);
    existing.insert(0, decision); // Newest first
    await saveDecisions(projectId, existing);
  }

  /// Whether a cached snapshot exists for [projectId].
  static bool hasCacheFor(String projectId) =>
      LocalStorageService.decisionsBox.containsKey(_keyFor(projectId));

  /// Clears cached decisions for [projectId].
  static Future<void> clearFor(String projectId) async {
    await LocalStorageService.decisionsBox.delete(_keyFor(projectId));
  }
}
