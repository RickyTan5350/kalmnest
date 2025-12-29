import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_codelab/constants/view_layout.dart';

class LayoutPreferences {
  static const _storage = FlutterSecureStorage();
  static const String globalLayoutKey = 'global_layout';
  static final Map<String, ViewLayout> _cache = {};

  // Save the selected layout for a specific page
  static Future<void> saveLayout(String pageKey, ViewLayout layout) async {
    _cache[pageKey] = layout;
    await _storage.write(key: 'layout_$pageKey', value: layout.name);
  }

  // Retrieve the saved layout for a specific page
  static Future<ViewLayout> getLayout(String pageKey) async {
    if (_cache.containsKey(pageKey)) {
      return _cache[pageKey]!;
    }

    final String? layoutName = await _storage.read(key: 'layout_$pageKey');
    if (layoutName == null) {
      return ViewLayout.grid; // Default
    }

    final layout = ViewLayout.values.firstWhere(
      (e) => e.name == layoutName,
      orElse: () => ViewLayout.grid,
    );
    _cache[pageKey] = layout;
    return layout;
  }

  // Synchronous retrieval from cache (for initialization)
  static ViewLayout getLayoutSync(String pageKey) {
    return _cache[pageKey] ?? ViewLayout.grid;
  }
}
