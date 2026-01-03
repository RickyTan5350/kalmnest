import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'level_storage_service.dart';

/// Implementation of LevelStorageService using local file system (dart:io)
class FileLevelStorageService implements LevelStorageService {
  static const String _folderName = 'unity_levels';

  /// Get the base directory for storing level files
  Future<Directory> _getLevelDirectory({String? userId}) async {
    final directory = await getApplicationSupportDirectory();
    String levelDirPath;
    if (userId != null && userId.isNotEmpty && userId != 'null') {
      levelDirPath = p.normalize(
        p.join(directory.path, _folderName, 'users', userId),
      );
    } else {
      levelDirPath = p.normalize(p.join(directory.path, _folderName));
    }
    final levelDir = Directory(levelDirPath);
    if (!await levelDir.exists()) {
      await levelDir.create(recursive: true);
    }
    return levelDir;
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
      final levelDir = await _getLevelDirectory(userId: userId);
      final levelTypeDirPath = p.normalize(p.join(levelDir.path, cleanLevelId));
      final levelTypeDir = Directory(levelTypeDirPath);

      if (!await levelTypeDir.exists()) {
        await levelTypeDir.create(recursive: true);
      }

      final levelDataObj = jsonDecode(jsonEncode(levelDataJson));
      final winDataObj = jsonDecode(jsonEncode(winConditionJson));
      final levelTypes = ['html', 'css', 'js', 'php'];

      final bool skipProgress =
          userRole != null &&
          (userRole.toLowerCase() == 'admin' ||
              userRole.toLowerCase() == 'teacher');

      for (final levelType in levelTypes) {
        final typeDirPath = p.normalize(p.join(levelTypeDir.path, levelType));
        final typeDir = Directory(typeDirPath);
        if (!await typeDir.exists()) {
          await typeDir.create(recursive: true);
        }

        final levelData = levelDataObj[levelType];
        if (levelData != null) {
          final levelDataFilePath = p.normalize(
            p.join(typeDir.path, 'levelData.json'),
          );
          final levelDataFile = File(levelDataFilePath);
          await levelDataFile.writeAsString(levelData);

          if (!skipProgress) {
            final progressTypeDirPath = p.normalize(
              p.join(levelDir.path, cleanLevelId, 'progress', levelType),
            );
            final progressTypeDir = Directory(progressTypeDirPath);
            if (!await progressTypeDir.exists()) {
              await progressTypeDir.create(recursive: true);
            }
            final progressDataFilePath = p.normalize(
              p.join(progressTypeDir.path, 'saved_data.json'),
            );
            final progressDataFile = File(progressDataFilePath);
            if (!await progressDataFile.exists()) {
              await progressDataFile.writeAsString(levelData);
            }
          }
        }

        final winData = winDataObj[levelType];
        if (winData != null) {
          final winDataFilePath = p.normalize(
            p.join(typeDir.path, 'winData.json'),
          );
          final winDataFile = File(winDataFilePath);
          await winDataFile.writeAsString(winData);
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Error saving level data: $e');
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
      final levelDir = await _getLevelDirectory(userId: userId);
      final progressDirPath = p.normalize(
        p.join(levelDir.path, cleanLevelId, 'progress'),
      );
      final progressDir = Directory(progressDirPath);
      if (!await progressDir.exists()) {
        await progressDir.create(recursive: true);
      }

      final savedDataObj = jsonDecode(savedDataJson);
      final levelTypes = ['html', 'css', 'js', 'php'];

      for (final levelType in levelTypes) {
        final typeDirPath = p.normalize(p.join(progressDir.path, levelType));
        final typeDir = Directory(typeDirPath);
        if (!await typeDir.exists()) {
          await typeDir.create(recursive: true);
        }
        final progressData = savedDataObj[levelType];
        if (progressData != null) {
          final progressFilePath = p.normalize(
            p.join(typeDir.path, 'saved_data.json'),
          );
          final progressFile = File(progressFilePath);
          await progressFile.writeAsString(progressData);
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Error saving student progress: $e');
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
    final cleanLevelId = levelId.trim();
    final cleanType = type.trim().toLowerCase();
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final filePath = p.normalize(
        p.join(levelDir.path, cleanLevelId, cleanType, '$dataType.json'),
      );
      final file = File(filePath);
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
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

    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final folder = effectiveUseProgress ? 'progress' : '';
      final fileName = (folder == 'progress' && cleanDataType == 'level')
          ? 'saved_data.json'
          : '${cleanDataType}Data.json';

      final filePath = folder.isEmpty
          ? p.normalize(
              p.join(levelDir.path, cleanLevelId, cleanType, fileName),
            )
          : p.normalize(
              p.join(levelDir.path, cleanLevelId, folder, cleanType, fileName),
            );

      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }

      if (effectiveUseProgress && cleanDataType == 'level' && !isStaff) {
        final baseFilePath = p.normalize(
          p.join(levelDir.path, cleanLevelId, cleanType, 'levelData.json'),
        );
        final baseFile = File(baseFilePath);
        if (await baseFile.exists()) {
          final content = await baseFile.readAsString();
          final progressFile = File(filePath);
          final progressDir = progressFile.parent;
          if (!await progressDir.exists()) {
            await progressDir.create(recursive: true);
          }
          await progressFile.writeAsString(content);
          return content;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getIndexFilePath({
    required String levelId,
    required String type,
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    final cleanType = type.trim().toLowerCase();
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final filePath = p.normalize(
        p.join(levelDir.path, cleanLevelId, 'Index', 'index.$cleanType'),
      );
      final file = File(filePath);
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
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
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final typeDirPath = p.normalize(
        p.join(levelDir.path, cleanLevelId, 'Index'),
      );
      final typeDir = Directory(typeDirPath);
      if (!await typeDir.exists()) {
        await typeDir.create(recursive: true);
      }
      final indexFilePath = p.normalize(
        p.join(typeDir.path, 'index.$cleanType'),
      );
      final indexFile = File(indexFilePath);
      await indexFile.writeAsString(content);
      return true;
    } catch (e) {
      return false;
    }
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
    } else {
      cleanDataType = cleanDataType
          .replaceAll('_data', '')
          .replaceAll('data', '');
    }

    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final typeDirPath = p.normalize(
        p.join(levelDir.path, cleanLevelId, cleanType),
      );
      final typeDir = Directory(typeDirPath);
      if (!await typeDir.exists()) {
        await typeDir.create(recursive: true);
      }
      final dataFilePath = p.normalize(
        p.join(typeDir.path, '${cleanDataType}Data.json'),
      );
      final dataFile = File(dataFilePath);
      await dataFile.writeAsString(content);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> clearLevelData(String levelId, {String? userId}) async {
    final cleanLevelId = levelId.trim();
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final levelTypeDirPath = p.normalize(p.join(levelDir.path, cleanLevelId));
      final levelTypeDir = Directory(levelTypeDirPath);
      if (await levelTypeDir.exists()) {
        await levelTypeDir.delete(recursive: true);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clearIndexFiles({
    required String levelId,
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final indexDirPath = p.normalize(
        p.join(levelDir.path, cleanLevelId, 'Index'),
      );
      final indexDir = Directory(indexDirPath);
      if (!await indexDir.exists()) {
        await indexDir.create(recursive: true);
      }
      final levelTypes = ['html', 'css', 'js', 'php'];
      for (final type in levelTypes) {
        final ext = type == 'js' ? 'js' : type;
        final indexFilePath = p.normalize(p.join(indexDirPath, 'index.$ext'));
        final indexFile = File(indexFilePath);
        await indexFile.writeAsString('');
      }
    } catch (e) {}
  }

  @override
  Future<Map<String, String>> readIndexFiles({
    required String levelId,
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    final Map<String, String> indexFiles = {};
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final indexDirPath = p.normalize(
        p.join(levelDir.path, cleanLevelId, 'Index'),
      );
      final indexDir = Directory(indexDirPath);
      if (await indexDir.exists()) {
        final levelTypes = ['html', 'css', 'js', 'php'];
        for (final type in levelTypes) {
          final ext = type == 'js' ? 'js' : type;
          final indexFilePath = p.normalize(p.join(indexDirPath, 'index.$ext'));
          final indexFile = File(indexFilePath);
          if (await indexFile.exists()) {
            indexFiles[type] = await indexFile.readAsString();
          }
        }
      }
    } catch (e) {}
    return indexFiles;
  }

  @override
  Future<String> getBasePath({String? userId}) async {
    final levelDir = await _getLevelDirectory(userId: userId);
    return p.normalize(levelDir.path);
  }
}
