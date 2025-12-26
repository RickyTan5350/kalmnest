import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Service to manage level data storage on local device
/// Handles saving and retrieving level data for Unity to use
class LocalLevelStorage {
  static const String _folderName = 'unity_levels';
  
  /// Get the base directory for storing level files
  Future<Directory> _getLevelDirectory({String? userId}) async {
    // Switching to ApplicationSupportDirectory as it is more reliable than Documents on Windows/OneDrive
    final directory = await getApplicationSupportDirectory();
    
    String levelDirPath;
    if (userId != null && userId.isNotEmpty && userId != 'null') {
      levelDirPath = p.normalize(p.join(directory.path, _folderName, 'users', userId));
    } else {
      levelDirPath = p.normalize(p.join(directory.path, _folderName));
    }
    
    final levelDir = Directory(levelDirPath);
    
    if (kDebugMode) {
      print('Target level storage directory: "$levelDirPath"');
    }

    if (!await levelDir.exists()) {
      try {
        await levelDir.create(recursive: true);
        if (kDebugMode) {
          print('Created level storage directory: ${levelDir.path}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('CRITICAL: Failed to create directory "$levelDirPath": $e');
        }
        rethrow;
      }
    }
    
    return levelDir;
  }

  /// Save level data to local storage
  /// Structure: {levelId}/{type}/levelData.json, winData.json, index.{type}
  Future<bool> saveLevelData({
    required String levelId,
    required Map<String, dynamic> levelDataJson,
    required Map<String, dynamic> winConditionJson,
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final levelTypeDirPath = p.normalize(p.join(levelDir.path, cleanLevelId));
      final levelTypeDir = Directory(levelTypeDirPath);
      
      if (kDebugMode) {
        print('Creating level type directory: "$levelTypeDirPath"');
      }

      if (!await levelTypeDir.exists()) {
        await levelTypeDir.create(recursive: true);
      }

      final levelDataObj = jsonDecode(jsonEncode(levelDataJson));
      final winDataObj = jsonDecode(jsonEncode(winConditionJson));
      
      final levelTypes = ['html', 'css', 'js', 'php'];
      
      for (final levelType in levelTypes) {
        final typeDirPath = p.normalize(p.join(levelTypeDir.path, levelType));
        final typeDir = Directory(typeDirPath);
        if (!await typeDir.exists()) {
          await typeDir.create(recursive: true);
        }
        
        // Save levelData
        final levelData = levelDataObj[levelType];
        if (levelData != null) {
          final levelDataFilePath = p.normalize(p.join(typeDir.path, 'levelData.json'));
          final levelDataFile = File(levelDataFilePath);
          if (!await levelDataFile.exists()) {
            await levelDataFile.writeAsString(levelData);
          }

          // Initialize progress folder with the same data if it doesn't exist
          final progressTypeDirPath = p.normalize(p.join(levelDir.path, cleanLevelId, 'progress', levelType));
          final progressTypeDir = Directory(progressTypeDirPath);
          if (!await progressTypeDir.exists()) {
            await progressTypeDir.create(recursive: true);
          }
          final progressDataFilePath = p.normalize(p.join(progressTypeDir.path, 'saved_data.json'));
          final progressDataFile = File(progressDataFilePath);
          if (!await progressDataFile.exists()) {
            await progressDataFile.writeAsString(levelData);
            if (kDebugMode) {
              print('Initialized default progress for $cleanLevelId/$levelType');
            }
          }

          if (kDebugMode) {
            print('Saved levelData for $cleanLevelId/$levelType');
          }
        }
        
        // Save winData
        final winData = winDataObj[levelType];
        if (winData != null) {
          final winDataFilePath = p.normalize(p.join(typeDir.path, 'winData.json'));
          final winDataFile = File(winDataFilePath);
          if (!await winDataFile.exists()) {
            await winDataFile.writeAsString(winData);
          }
          if (kDebugMode) {
            print('Saved winData for $levelId/$levelType');
          }
        }
      }

      // --- ADDED: Create index folder for preview ---
      final indexDirPath = p.normalize(p.join(levelTypeDir.path, 'index'));
      final indexDir = Directory(indexDirPath);
      if (!await indexDir.exists()) {
        await indexDir.create(recursive: true);
      }

      for (final levelType in levelTypes) {
        final levelData = levelDataObj[levelType];
        if (levelData != null) {
          final ext = levelType == 'js' ? 'js' : levelType;
          final indexFilePath = p.normalize(p.join(indexDirPath, 'index.$ext'));
          await File(indexFilePath).writeAsString(levelData);
        }
      }
      // ----------------------------------------------
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving level data: $e');
      }
      return false;
    }
  }

  /// Save student's progress data (saved_data from level_user table)
  Future<bool> saveStudentProgress({
    required String levelId,
    required String? savedDataJson,
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    try {
      if (savedDataJson == null) return true;
      
      final levelDir = await _getLevelDirectory(userId: userId);
      final progressDirPath = p.normalize(p.join(levelDir.path, cleanLevelId, 'progress'));
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
          final progressFilePath = p.normalize(p.join(typeDir.path, 'saved_data.json'));
          final progressFile = File(progressFilePath);
          await progressFile.writeAsString(progressData);
          if (kDebugMode) {
            print('Saved progress for $cleanLevelId/$levelType');
          }

          // --- ADDED: Update index folder for preview ---
          final levelTypeDir = progressDir.parent;
          final indexDirPath = p.normalize(p.join(levelTypeDir.path, 'index'));
          final indexDir = Directory(indexDirPath);
          if (!await indexDir.exists()) {
            await indexDir.create(recursive: true);
          }
          final ext = levelType == 'js' ? 'js' : levelType;
          final indexFilePath = p.normalize(p.join(indexDirPath, 'index.$ext'));
          await File(indexFilePath).writeAsString(progressData);
          // ----------------------------------------------
        }
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving student progress: $e');
      }
      return false;
    }
  }

  /// Get file path for Unity to read
  /// Returns the local file path that Unity can access
  Future<String?> getFilePath({
    required String levelId,
    required String type, // html, css, js, php
    required String dataType, // levelData, winData
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    final cleanType = type.trim().toLowerCase();
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final filePath = p.normalize(p.join(levelDir.path, cleanLevelId, cleanType, '${dataType}.json'));
      final file = File(filePath);
      
      if (await file.exists()) {
        return file.path;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting file path: $e');
      }
      return null;
    }
  }

  /// Get file content as string (for Unity WebGL via HTTP)
  Future<String?> getFileContent({
    required String levelId,
    required String type,
    required String dataType,
    bool useProgress = false, // If true, get from progress folder
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    final cleanType = type.trim().toLowerCase();
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final folder = useProgress ? 'progress' : '';
      
      // Map levelData to saved_data.json when using progress folder
      final fileName = (folder == 'progress' && dataType == 'level') 
          ? 'saved_data.json' 
          : '${dataType}Data.json';

      final filePath = folder.isEmpty
          ? p.normalize(p.join(levelDir.path, cleanLevelId, cleanType, fileName))
          : p.normalize(p.join(levelDir.path, cleanLevelId, folder, cleanType, fileName));
      
      final file = File(filePath);
      
      if (await file.exists()) {
        return await file.readAsString();
      }

      // If progress file doesn't exist, fall back to base level data and initialize progress
      if (useProgress && dataType == 'level') {
        final baseFilePath = p.normalize(p.join(levelDir.path, cleanLevelId, cleanType, 'levelData.json'));
        final baseFile = File(baseFilePath);
        if (await baseFile.exists()) {
          final content = await baseFile.readAsString();
          // Initialize the progress file for next time
          final progressFile = File(filePath);
          final progressDir = progressFile.parent;
          if (!await progressDir.exists()) {
            await progressDir.create(recursive: true);
          }
          await progressFile.writeAsString(content);
          if (kDebugMode) {
            print('Initialized default progress on-demand for $cleanLevelId/$cleanType');
          }
          return content;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting file content: $e');
      }
      return null;
    }
  }

  /// Get index file path (for save-index route)
  Future<String?> getIndexFilePath({
    required String levelId,
    required String type,
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    final cleanType = type.trim().toLowerCase();
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final filePath = p.normalize(p.join(levelDir.path, cleanLevelId, cleanType, 'index.$cleanType'));
      final file = File(filePath);
      
      if (await file.exists()) {
        return file.path;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting index file path: $e');
      }
      return null;
    }
  }

  /// Save index file content
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
      final typeDirPath = p.normalize(p.join(levelDir.path, cleanLevelId, cleanType));
      final typeDir = Directory(typeDirPath);
      
      if (!await typeDir.exists()) {
        await typeDir.create(recursive: true);
      }
      
      final indexFilePath = p.normalize(p.join(typeDir.path, 'index.$cleanType'));
      final indexFile = File(indexFilePath);
      await indexFile.writeAsString(content);
      
      if (kDebugMode) {
        print('Saved index file for $levelId/$type');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving index file: $e');
      }
      return false;
    }
  }

  /// Save data file (for save-data route during level creation)
  Future<bool> saveDataFile({
    required String levelId,
    required String type,
    required String dataType, // level or win
    required String content,
    String? userId,
  }) async {
    final cleanLevelId = levelId.trim();
    final cleanType = type.trim().toLowerCase();
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final typeDirPath = p.normalize(p.join(levelDir.path, cleanLevelId, cleanType));
      final typeDir = Directory(typeDirPath);
      
      if (!await typeDir.exists()) {
        await typeDir.create(recursive: true);
      }
      
      final dataFilePath = p.normalize(p.join(typeDir.path, '${dataType}Data.json'));
      final dataFile = File(dataFilePath);
      await dataFile.writeAsString(content);
      
      if (kDebugMode) {
        print('Saved ${dataType}Data for $levelId/$type');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving data file: $e');
      }
      return false;
    }
  }

  /// Clear all level data for a specific level
  Future<bool> clearLevelData(String levelId, {String? userId}) async {
    final cleanLevelId = levelId.trim();
    try {
      final levelDir = await _getLevelDirectory(userId: userId);
      final levelTypeDirPath = p.normalize(p.join(levelDir.path, cleanLevelId));
      final levelTypeDir = Directory(levelTypeDirPath);
      
      if (await levelTypeDir.exists()) {
        await levelTypeDir.delete(recursive: true);
        if (kDebugMode) {
          print('Cleared level data for $levelId');
        }
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing level data: $e');
      }
      return false;
    }
  }

  /// Get the base path for serving files via HTTP (for Unity WebGL)
  Future<String> getBasePath({String? userId}) async {
    final levelDir = await _getLevelDirectory(userId: userId);
    return levelDir.path;
  }
}




