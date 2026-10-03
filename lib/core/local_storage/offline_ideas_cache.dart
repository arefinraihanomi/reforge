import 'dart:convert';

import '../../features/ideas/models/idea.dart';
import 'local_storage_service.dart';

/// Offline cache for the ideas list using Hive.
///
/// Persists the raw JSON of ideas locally so the Idea Vault renders
/// immediately from cache while a fresh network fetch runs in the background.
class OfflineIdeasCache {
  static const String _listKey = 'cached_ideas_list';

  /// Stores the list of ideas to local cache as JSON.
  ///
  /// Uses [Idea.toInsertJson] for fields plus id/timestamps for round-trip.
  static Future<void> saveIdeas(List<Idea> ideas) async {
    final jsonList = ideas.map((idea) {
      final map = idea.toInsertJson();
      // Augment with fields toInsertJson omits
      map['id'] = idea.id;
      map['idea_number'] = idea.ideaNumber;
      map['created_at'] = idea.createdAt.toIso8601String();
      map['updated_at'] = idea.updatedAt.toIso8601String();
      // Encode tags as a simple list of {id, name} maps
      map['_cached_tags'] =
          idea.tags.map((t) => {'id': t.id, 'name': t.name}).toList();
      return jsonEncode(map);
    }).toList();
    await LocalStorageService.ideasBox.put(_listKey, jsonEncode(jsonList));
  }

  /// Loads cached ideas. Returns an empty list if no cache is available.
  static List<Idea> loadIdeas() {
    final raw = LocalStorageService.ideasBox.get(_listKey);
    if (raw == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList.map((item) {
        final map = jsonDecode(item as String) as Map<String, dynamic>;
        return Idea.fromJson(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Clears the ideas cache.
  static Future<void> clear() async {
    await LocalStorageService.ideasBox.delete(_listKey);
  }

  /// Whether a cached snapshot exists.
  static bool get hasCache => LocalStorageService.ideasBox.containsKey(_listKey);
}
