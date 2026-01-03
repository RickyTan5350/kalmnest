import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'level_storage_service.dart';

/// Implementation of LevelStorageService for Web using localStorage
/// We use universal_html to safely access window.localStorage without breaking non-web builds during compilation if mixed.
class WebLevelStorageService implements LevelStorageService {
  static const String _storagePrefix = 'unity_levels';

  // Helper to generate storage key
  String _getKey(String part, [String? userId]) {
    final uid = (userId != null && userId.isNotEmpty && userId != 'null')
        ? userId
        : 'default';
    return '$_storagePrefix/$uid/$part';
  }

  @override
  Future<bool> saveLevelData({
    required String levelId,
    required Map<String, dynamic> levelDataJson,
    required Map<String, dynamic> winConditionJson,
    String? userId,
    String? userRole,
  }) async {
    final cleanLevelId = levelId.trim();
    try {
      final levelDataObj = jsonDecode(jsonEncode(levelDataJson));
      final winDataObj = jsonDecode(jsonEncode(winConditionJson));
      final levelTypes = ['html', 'css', 'js', 'php'];

      final bool skipProgress =
          userRole != null &&
          (userRole.toLowerCase() == 'admin' ||
              userRole.toLowerCase() == 'teacher');

      for (final levelType in levelTypes) {
        // Save levelData
        final levelData = levelDataObj[levelType];
        if (levelData != null) {
          final levelKey = _getKey(
            '$cleanLevelId/$levelType/levelData.json',
            userId,
          );
          web.window.localStorage[levelKey] = levelData.toString();

          if (!skipProgress) {
            // Save initial progress
            final progressKey = _getKey(
              '$cleanLevelId/progress/$levelType/saved_data.json',
              userId,
            );
            bool hasKey = web.window.localStorage[progressKey] != null;
            if (!hasKey) {
              web.window.localStorage[progressKey] = levelData.toString();
            }
          }
        }

        // Save winData
        final winData = winDataObj[levelType];
        if (winData != null) {
          final winKey = _getKey(
            '$cleanLevelId/$levelType/winData.json',
            userId,
          );
          web.window.localStorage[winKey] = winData.toString();
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Error saving level data (Web): $e');
      return false;
    }
  }

  @override
  Future<bool> saveStudentProgress({
    required String levelId,
    required String? savedDataJson,
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    try {
      if (savedDataJson == null) return true;
      final savedDataObj = jsonDecode(savedDataJson);
      final levelTypes = ['html', 'css', 'js', 'php'];

      for (final levelType in levelTypes) {
        final progressData = savedDataObj[levelType];
        if (progressData != null) {
          final progressKey = _getKey(
            '$cleanLevelId/progress/$levelType/saved_data.json',
            userId,
          );
          web.window.localStorage[progressKey] = progressData.toString();
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getFilePath({
    required String levelId,
    required String type,
    required String dataType,
    String? userId,
  }) async {
    // On web, there is no file path. Return null or a dummy string.
    // Unity on Web won't use this anyway if we handle it correctly.
    return null;
  }

  @override
  Future<String?> getFileContent({
    required String levelId,
    required String type,
    required String dataType,
    bool useProgress = false,
    String? userId,
    String? userRole,
  }) async {
    final cleanLevelId = levelId.trim();
    final cleanType = type.trim().toLowerCase();
    String cleanDataType = dataType.trim().toLowerCase();
    if (cleanDataType.contains('win')) {
      cleanDataType = 'win';
    } else if (cleanDataType.contains('level')) {
      cleanDataType = 'level';
    } else {
      cleanDataType = cleanDataType
          .replaceAll('_data', '')
          .replaceAll('data', '');
    }

    final bool isStaff =
        userRole != null &&
        (userRole.toLowerCase() == 'admin' ||
            userRole.toLowerCase() == 'teacher');
    final bool effectiveUseProgress = isStaff ? false : useProgress;

    // Construct Key
    String folder = effectiveUseProgress ? 'progress' : '';
    final fileName = (folder == 'progress' && cleanDataType == 'level')
        ? 'saved_data.json'
        : '${cleanDataType}Data.json';

    // Path string used in key
    String path = folder.isEmpty
        ? '$cleanLevelId/$cleanType/$fileName'
        : '$cleanLevelId/$folder/$cleanType/$fileName';

    final key = _getKey(path, userId);

    if (web.window.localStorage[key] != null) {
      return web.window.localStorage[key];
    }

    // Fallback logic
    if (effectiveUseProgress && cleanDataType == 'level' && !isStaff) {
      final baseKey = _getKey(
        '$cleanLevelId/$cleanType/levelData.json',
        userId,
      );
      if (web.window.localStorage[baseKey] != null) {
        final content = web.window.localStorage[baseKey];
        if (content != null) {
          web.window.localStorage[key] = content;
          return content;
        }
      }
    }
    return null;
  }

  @override
  Future<String?> getIndexFilePath({
    required String levelId,
    required String type,
    String? userId,
  }) async {
    return null; // No file path on web
  }

  @override
  Future<bool> saveIndexFile({
    required String levelId,
    required String type,
    required String content,
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    final cleanType = type.trim().toLowerCase();
    final key = _getKey('$cleanLevelId/Index/index.$cleanType', userId);
    web.window.localStorage[key] = content;
    return true;
  }

  @override
  Future<bool> saveDataFile({
    required String levelId,
    required String type,
    required String dataType,
    required String content,
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    final cleanType = type.trim().toLowerCase();
    String cleanDataType = dataType.trim().toLowerCase();
    if (cleanDataType.contains('win')) {
      cleanDataType = 'win';
    } else if (cleanDataType.contains('level')) {
      cleanDataType = 'level';
    }

    // Determine filename
    final fileName = '${cleanDataType}Data.json';
    final key = _getKey('$cleanLevelId/$cleanType/$fileName', userId);
    web.window.localStorage[key] = content;
    return true;
  }

  @override
  Future<bool> clearLevelData(String levelId, {String? userId}) async {
    // This is harder on web as we can't iterate directory easily without storing keys list.
    // For simplicity, we skip full wipe or we just clear standard keys if we know them.
    // Ideally we would store a list of keys in another localStorage item.
    // But for now, we'll implement a 'best effort' clear if we track paths.
    // Since this is just for session, we might not strictly need to clear everything.
    return true;
  }

  @override
  Future<void> clearIndexFiles({
    required String levelId,
    String? userId,
  }) async {
    final levelTypes = ['html', 'css', 'js', 'php'];
    for (final type in levelTypes) {
      final ext = type == 'js' ? 'js' : type;
      final key = _getKey('$levelId/Index/index.$ext', userId);
      web.window.localStorage[key] = '';
    }
  }

  @override
  Future<Map<String, String>> readIndexFiles({
    required String levelId,
    String? userId,
  }) async {
    final Map<String, String> indexFiles = {};
    final levelTypes = ['html', 'css', 'js', 'php'];
    for (final type in levelTypes) {
      final ext = type == 'js' ? 'js' : type;
      final key = _getKey('$levelId/Index/index.$ext', userId);
      if (web.window.localStorage[key] != null) {
        indexFiles[type] = web.window.localStorage[key]!;
      }
    }
    return indexFiles;
  }

  @override
  Future<String> getBasePath({String? userId}) async {
    return ''; // No base path needed for web
  }
}
