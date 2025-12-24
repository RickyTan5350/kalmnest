import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Service to manage level data storage on local device
/// Handles saving and retrieving level data for Unity to use
class LocalLevelStorage {
  static const String _folderName = 'unity_levels';
  
  /// Get the base directory for storing level files
  Future<Directory> _getLevelDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final levelDir = Directory('${directory.path}/$_folderName');
    
    if (!await levelDir.exists()) {
      await levelDir.create(recursive: true);
      if (kDebugMode) {
        print('Created level storage directory: ${levelDir.path}');
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
  }) async {
    try {
      final levelDir = await _getLevelDirectory();
      final levelTypeDir = Directory('${levelDir.path}/$levelId');
      
      if (!await levelTypeDir.exists()) {
        await levelTypeDir.create(recursive: true);
      }

      final levelDataObj = jsonDecode(jsonEncode(levelDataJson));
      final winDataObj = jsonDecode(jsonEncode(winConditionJson));
      
      final levelTypes = ['html', 'css', 'js', 'php'];
      
      for (final levelType in levelTypes) {
        final typeDir = Directory('${levelTypeDir.path}/$levelType');
        if (!await typeDir.exists()) {
          await typeDir.create(recursive: true);
        }
        
        // Save levelData
        final levelData = levelDataObj[levelType];
        if (levelData != null) {
          final levelDataFile = File('${typeDir.path}/levelData.json');
          await levelDataFile.writeAsString(levelData);
          if (kDebugMode) {
            print('Saved levelData for $levelId/$levelType');
          }
        }
        
        // Save winData
        final winData = winDataObj[levelType];
        if (winData != null) {
          final winDataFile = File('${typeDir.path}/winData.json');
          await winDataFile.writeAsString(winData);
          if (kDebugMode) {
            print('Saved winData for $levelId/$levelType');
          }
        }
      }
      
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
  }) async {
    try {
      if (savedDataJson == null) return true;
      
      final levelDir = await _getLevelDirectory();
      final progressDir = Directory('${levelDir.path}/$levelId/progress');
      
      if (!await progressDir.exists()) {
        await progressDir.create(recursive: true);
      }

      final savedDataObj = jsonDecode(savedDataJson);
      final levelTypes = ['html', 'css', 'js', 'php'];
      
      for (final levelType in levelTypes) {
        final typeDir = Directory('${progressDir.path}/$levelType');
        if (!await typeDir.exists()) {
          await typeDir.create(recursive: true);
        }
        
        final progressData = savedDataObj[levelType];
        if (progressData != null) {
          final progressFile = File('${typeDir.path}/levelData.json');
          await progressFile.writeAsString(progressData);
          if (kDebugMode) {
            print('Saved progress for $levelId/$levelType');
          }
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
  }) async {
    try {
      final levelDir = await _getLevelDirectory();
      final filePath = '${levelDir.path}/$levelId/$type/${dataType}.json';
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
  }) async {
    try {
      final levelDir = await _getLevelDirectory();
      final folder = useProgress ? 'progress' : '';
      final filePath = folder.isEmpty
          ? '${levelDir.path}/$levelId/$type/${dataType}.json'
          : '${levelDir.path}/$levelId/$folder/$type/${dataType}.json';
      
      final file = File(filePath);
      
      if (await file.exists()) {
        return await file.readAsString();
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
  }) async {
    try {
      final levelDir = await _getLevelDirectory();
      final filePath = '${levelDir.path}/$levelId/$type/index.$type';
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
  }) async {
    try {
      final levelDir = await _getLevelDirectory();
      final typeDir = Directory('${levelDir.path}/$levelId/$type');
      
      if (!await typeDir.exists()) {
        await typeDir.create(recursive: true);
      }
      
      final indexFile = File('${typeDir.path}/index.$type');
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
  }) async {
    try {
      final levelDir = await _getLevelDirectory();
      final typeDir = Directory('${levelDir.path}/$levelId/$type');
      
      if (!await typeDir.exists()) {
        await typeDir.create(recursive: true);
      }
      
      final dataFile = File('${typeDir.path}/${dataType}Data.json');
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
  Future<bool> clearLevelData(String levelId) async {
    try {
      final levelDir = await _getLevelDirectory();
      final levelTypeDir = Directory('${levelDir.path}/$levelId');
      
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
  Future<String> getBasePath() async {
    final levelDir = await _getLevelDirectory();
    return levelDir.path;
  }
}




