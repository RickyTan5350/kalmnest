import 'package:flutter/foundation.dart';
import 'package:code_play/services/level_storage/level_storage_service.dart';
import 'package:code_play/services/level_storage/file_level_storage_service.dart'
    if (dart.library.js_interop) 'package:code_play/services/level_storage/file_level_storage_dummy.dart';
import 'package:code_play/services/level_storage/web_level_storage_service.dart'
    if (dart.library.io) 'package:code_play/services/level_storage/web_level_storage_dummy.dart';

/// Service to manage level data storage on local device or web
/// Wrapper that delegates to platform specific implementation
class LocalLevelStorage implements LevelStorageService {
  final LevelStorageService _service;

  LocalLevelStorage()
    : _service = kIsWeb ? WebLevelStorageService() : FileLevelStorageService();

  @override
  Future<bool> saveLevelData({
    required String levelId,
    required Map<String, dynamic> levelDataJson,
    required Map<String, dynamic> winConditionJson,
    String? userId,
    String? userRole,
  }) => _service.saveLevelData(
    levelId: levelId,
    levelDataJson: levelDataJson,
    winConditionJson: winConditionJson,
    userId: userId,
    userRole: userRole,
  );

  @override
  Future<bool> saveStudentProgress({
    required String levelId,
    required String? savedDataJson,
    String? userId,
  }) => _service.saveStudentProgress(
    levelId: levelId,
    savedDataJson: savedDataJson,
    userId: userId,
  );

  @override
  Future<String?> getFilePath({
    required String levelId,
    required String type,
    required String dataType,
    String? userId,
  }) => _service.getFilePath(
    levelId: levelId,
    type: type,
    dataType: dataType,
    userId: userId,
  );

  @override
  Future<String?> getFileContent({
    required String levelId,
    required String type,
    required String dataType,
    bool useProgress = false,
    String? userId,
    String? userRole,
  }) => _service.getFileContent(
    levelId: levelId,
    type: type,
    dataType: dataType,
    useProgress: useProgress,
    userId: userId,
    userRole: userRole,
  );

  @override
  Future<String?> getIndexFilePath({
    required String levelId,
    required String type,
    String? userId,
  }) => _service.getIndexFilePath(levelId: levelId, type: type, userId: userId);

  @override
  Future<bool> saveIndexFile({
    required String levelId,
    required String type,
    required String content,
    String? userId,
  }) => _service.saveIndexFile(
    levelId: levelId,
    type: type,
    content: content,
    userId: userId,
  );

  @override
  Future<bool> saveDataFile({
    required String levelId,
    required String type,
    required String dataType,
    required String content,
    String? userId,
  }) => _service.saveDataFile(
    levelId: levelId,
    type: type,
    dataType: dataType,
    content: content,
    userId: userId,
  );

  @override
  Future<bool> clearLevelData(String levelId, {String? userId}) =>
      _service.clearLevelData(levelId, userId: userId);

  @override
  Future<void> clearIndexFiles({required String levelId, String? userId}) =>
      _service.clearIndexFiles(levelId: levelId, userId: userId);

  @override
  Future<Map<String, String>> readIndexFiles({
    required String levelId,
    String? userId,
  }) => _service.readIndexFiles(levelId: levelId, userId: userId);

  @override
  Future<String> getBasePath({String? userId}) =>
      _service.getBasePath(userId: userId);
}
