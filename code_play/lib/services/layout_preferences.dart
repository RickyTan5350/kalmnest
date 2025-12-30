import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_codelab/constants/view_layout.dart';

class LayoutPreferences {
  static const _storage = FlutterSecureStorage();

  // Save the selected layout for a specific page
  static Future<void> saveLayout(String pageKey, ViewLayout layout) async {
    await _storage.write(key: 'layout_$pageKey', value: layout.name);
  }

  // Retrieve the saved layout for a specific page
  static Future<ViewLayout> getLayout(String pageKey) async {
    final String? layoutName = await _storage.read(key: 'layout_$pageKey');
    if (layoutName == null) {
      return ViewLayout.grid; // Default
    }
    return ViewLayout.values.firstWhere(
      (e) => e.name == layoutName,
      orElse: () => ViewLayout.grid,
    );
  }
}
