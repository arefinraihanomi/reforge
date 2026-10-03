import 'package:hive_flutter/hive_flutter.dart';

/// Keys used to identify local Hive storage boxes.
abstract final class LocalStorageKeys {
  static const String ideasCache = 'ideas_cache';
  static const String decisionsCache = 'decisions_cache';
  static const String settingsBox = 'app_settings';
}

/// Singleton service initializing and exposing Hive boxes.
///
/// Call [LocalStorageService.init] once at app startup before using any cache.
class LocalStorageService {
  LocalStorageService._();

  static bool _initialized = false;

  /// Initializes Hive and opens all app storage boxes.
  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(LocalStorageKeys.ideasCache),
      Hive.openBox<String>(LocalStorageKeys.decisionsCache),
      Hive.openBox<String>(LocalStorageKeys.settingsBox),
    ]);
    _initialized = true;
  }

  /// Returns the ideas cache box. Must call [init] first.
  static Box<String> get ideasBox => Hive.box<String>(LocalStorageKeys.ideasCache);

  /// Returns the decisions cache box. Must call [init] first.
  static Box<String> get decisionsBox => Hive.box<String>(LocalStorageKeys.decisionsCache);

  /// Returns the settings box. Must call [init] first.
  static Box<String> get settingsBox => Hive.box<String>(LocalStorageKeys.settingsBox);

  /// Clears all local caches. Useful on sign-out.
  static Future<void> clearAll() async {
    await ideasBox.clear();
    await decisionsBox.clear();
    await settingsBox.clear();
  }
}
