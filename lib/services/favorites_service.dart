import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which tabs the user has pinned to the bottom navigation bar.
/// Settings is always shown and is not included in this list.
class FavoritesService extends ChangeNotifier {
  static const String _prefsKey = 'favoriteTabs';
  static const String defaultFavorites = 'explore,waterfalls,alerts,search';

  // Canonical display order — Search is always last among favorites.
  static const List<String> _canonicalOrder = [
    'explore', 'waterfalls', 'alerts',
    'hiking', 'running', 'biking', 'climbing', 'skiing', 'rivers',
    'search',
  ];

  List<String> _favorites = defaultFavorites.split(',');
  bool _loaded = false;

  /// Returns favorites in canonical order (Search always last).
  List<String> get favorites {
    final sorted = List<String>.from(_favorites);
    sorted.sort((a, b) {
      final ai = _canonicalOrder.indexOf(a);
      final bi = _canonicalOrder.indexOf(b);
      final aOrder = ai >= 0 ? ai : 999;
      final bOrder = bi >= 0 ? bi : 999;
      return aOrder.compareTo(bOrder);
    });
    return List.unmodifiable(sorted);
  }
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _favorites = (saved ?? defaultFavorites).split(',');
    _loaded = true;
    notifyListeners();
  }

  Future<void> setFavorites(List<String> tabs) async {
    _favorites = List<String>.from(tabs);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, tabs.join(','));
    notifyListeners();
  }

  Future<void> toggle(String tabName) async {
    final updated = List<String>.from(_favorites);
    if (updated.contains(tabName)) {
      if (updated.length > 1) updated.remove(tabName);
    } else {
      updated.add(tabName);
    }
    await setFavorites(updated);
  }

  Future<void> resetToDefault() async {
    await setFavorites(defaultFavorites.split(','));
  }

  bool contains(String tabName) => _favorites.contains(tabName);
}
