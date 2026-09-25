import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which templates the user actually reaches for.
///
/// Ids only. The template itself ships with the app, so storing anything more
/// would go stale the moment a look is retuned.
abstract class RecentTemplateStore {
  Future<List<String>> load();
  Future<void> remember(String id);
}

class PrefsRecentTemplateStore implements RecentTemplateStore {
  const PrefsRecentTemplateStore();

  static const String _key = 'recent_template_ids';
  static const int maxEntries = 6;

  @override
  Future<List<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? const [];
    } catch (error) {
      // A missing preferences store is not worth failing the Create tab over.
      debugPrint('[templates] could not read recents: $error');
      return const [];
    }
  }

  @override
  Future<void> remember(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_key) ?? <String>[];
      // Most recent first, no duplicates: reusing a template moves it up
      // rather than adding a second entry.
      final next = [id, ...current.where((e) => e != id)].take(maxEntries).toList();
      await prefs.setStringList(_key, next);
    } catch (error) {
      debugPrint('[templates] could not save a recent: $error');
    }
  }
}

class InMemoryRecentTemplateStore implements RecentTemplateStore {
  InMemoryRecentTemplateStore([List<String> seed = const []])
      : _ids = List<String>.from(seed);

  final List<String> _ids;

  @override
  Future<List<String>> load() async => List.unmodifiable(_ids);

  @override
  Future<void> remember(String id) async {
    _ids
      ..removeWhere((e) => e == id)
      ..insert(0, id);
    if (_ids.length > PrefsRecentTemplateStore.maxEntries) {
      _ids.removeRange(PrefsRecentTemplateStore.maxEntries, _ids.length);
    }
  }
}
