import 'package:web/web.dart' as web;
import 'dart:js_interop';

class WebUtils {
  static bool get isWeb => true;

  static String createBlobUrl(String content, String mimeType) {
    try {
      final blob = web.Blob(
        [content.toJS].toJS,
        web.BlobPropertyBag(type: mimeType),
      );
      return web.URL.createObjectURL(blob);
    } catch (e) {
      print('Error creating blob URL: $e');
      return '';
    }
  }

  static void revokeBlobUrl(String url) {
    try {
      web.URL.revokeObjectURL(url);
    } catch (e) {
      print('Error revoking blob URL: $e');
    }
  }

  static String? getFromLocalStorage(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } catch (e) {
      print('Error reading from localStorage: $e');
      return null;
    }
  }

  static void setToLocalStorage(String key, String value) {
    try {
      web.window.localStorage.setItem(key, value);
    } catch (e) {
      print('Error writing to localStorage: $e');
    }
  }

  static void removeFromLocalStorage(String key) {
    try {
      web.window.localStorage.removeItem(key);
    } catch (e) {
      print('Error removing from localStorage: $e');
    }
  }
}
