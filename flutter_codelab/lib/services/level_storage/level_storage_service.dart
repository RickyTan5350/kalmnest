/// Abstract interface for Level Storage
abstract class LevelStorageService {
  Future<bool> saveLevelData({
    required String levelId,
    required Map<String, dynamic> levelDataJson,
    required Map<String, dynamic> winConditionJson,
    String? userId,
    String? userRole,
  });

  Future<bool> saveStudentProgress({
    required String levelId,
    required String? savedDataJson,
    String? userId,
  });

  Future<String?> getFilePath({
    required String levelId,
    required String type,
    required String dataType,
    String? userId,
  });

  Future<String?> getFileContent({
    required String levelId,
    required String type,
    required String dataType,
    bool useProgress = false,
    String? userId,
    String? userRole,
  });

  Future<String?> getIndexFilePath({
    required String levelId,
    required String type,
    String? userId,
  });

  Future<bool> saveIndexFile({
    required String levelId,
    required String type,
    required String content,
    String? userId,
  });

  Future<bool> saveDataFile({
    required String levelId,
    required String type,
    required String dataType,
    required String content,
    String? userId,
  });

  Future<bool> clearLevelData(String levelId, {String? userId});

  Future<void> clearIndexFiles({required String levelId, String? userId});

  Future<Map<String, String>> readIndexFiles({
    required String levelId,
    String? userId,
  });

  Future<String> getBasePath({String? userId});
}
