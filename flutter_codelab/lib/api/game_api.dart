import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:code_play/models/level.dart';
import 'package:code_play/api/auth_api.dart';
import 'package:code_play/constants/api_constants.dart';
import 'package:code_play/services/local_level_storage.dart';
import 'package:flutter/foundation.dart';

/// CENTRAL API BASE URL
String get apiBase => ApiConstants.baseUrl;

class ApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ApiResponse({required this.success, required this.message, this.data});
}

class GameAPI {
  /// Helper to get headers with Auth Token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthApi.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (ApiConstants.customBaseUrl.isEmpty) 'Host': 'kalmnest.test',
    };
  }

  /// ------------------------------------------------------------
  /// FETCH ALL LEVELS (OPTIONALLY FILTER BY TOPIC)
  /// ------------------------------------------------------------
  // Cache per user (using user ID from token)
  static Map<String, List<LevelModel>?> _cachedLevelsByUser = {};

  /// Clear cache for all users (useful when game is created/updated)
  static void clearCache() {
    _cachedLevelsByUser.clear();
  }

  /// Get cache key from current user token
  static Future<String?> _getCacheKey() async {
    final token = await AuthApi.getToken();
    if (token == null) return null;
    // Use a simple hash of token as cache key (or extract user ID if available)
    return token.substring(0, math.min(20, token.length));
  }

  /// ------------------------------------------------------------
  /// FETCH ALL LEVELS (OPTIONALLY FILTER BY TOPIC)
  /// ------------------------------------------------------------
  static Future<List<LevelModel>> fetchLevels({
    String? topic,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = await _getCacheKey();

      // Clear cache if force refresh
      if (forceRefresh) {
        if (cacheKey != null) {
          _cachedLevelsByUser[cacheKey] = null;
        } else {
          _cachedLevelsByUser.clear();
        }
      }

      // Return cached levels if available and not forced to refresh
      if (!forceRefresh &&
          cacheKey != null &&
          _cachedLevelsByUser[cacheKey] != null &&
          topic == null) {
        return _cachedLevelsByUser[cacheKey]!;
      }

      final query = (topic != null && topic != "All") ? "?topic=$topic" : "";
      final url = Uri.parse("$apiBase/levels$query");
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        final levels = decoded
            .map((json) => LevelModel.fromJson(json))
            .toList();

        // Cache the result if we fetched all levels (no topic filter)
        if (topic == null && cacheKey != null) {
          _cachedLevelsByUser[cacheKey] = levels;
        }
        return levels;
      }

      print("Failed to fetch levels: ${response.statusCode}");
      print(response.body);
      return [];
    } catch (e) {
      print("Error fetching levels: $e");
      return [];
    }
  }

  /// ------------------------------------------------------------
  /// FETCH A SINGLE LEVEL BY ID → RETURNS LevelModel?
  /// ------------------------------------------------------------
  static Future<LevelModel?> fetchLevelById(
    String levelId, {
    String? userRole,
  }) async {
    try {
      final url = Uri.parse("$apiBase/level/$levelId");
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final level = LevelModel.fromJson(jsonData);

        // Save level data to local storage for Unity to access
        if (level.levelData != null && level.winCondition != null) {
          final storage = LocalLevelStorage();
          final levelDataJson = jsonDecode(level.levelData!);
          final winConditionJson = jsonDecode(level.winCondition!);

          final user = await AuthApi.getStoredUser();
          final userId = user?['user_id']?.toString();
          final role = userRole ?? user?['role']?.toString();
          final bool isStaff =
              role != null &&
              (role.toLowerCase() == 'admin' ||
                  role.toLowerCase() == 'teacher');

          await storage.saveLevelData(
            levelId: levelId,
            levelDataJson: levelDataJson,
            winConditionJson: winConditionJson,
            userId: userId,
            userRole: role,
          );

          // Also try to load and save student progress if exists (SKIP for admins/teachers)
          if (!isStaff) {
            final progressUrl = Uri.parse("$apiBase/level-user/$levelId");
            try {
              final progressResponse = await http.get(
                progressUrl,
                headers: headers,
              );
              if (progressResponse.statusCode == 200) {
                final progressData = jsonDecode(progressResponse.body);
                if (progressData['saved_data'] != null) {
                  await storage.saveStudentProgress(
                    levelId: levelId,
                    savedDataJson: progressData['saved_data'] is String
                        ? progressData['saved_data']
                        : jsonEncode(progressData['saved_data']),
                    userId: userId,
                  );
                  if (kDebugMode) {
                    print("Loaded backend progress for level $levelId");
                  }
                }
              }
            } catch (e) {
              // Progress may not exist yet, which is fine
              print("No saved progress found for level: $levelId");
            }
          }
        }

        return level;
      }

      print("Failed to fetch level: ${response.statusCode}");
      return null;
    } catch (e) {
      print("Error fetching level: $e");
      return null;
    }
  }

  /// ------------------------------------------------------------
  /// CREATE LEVEL
  /// ------------------------------------------------------------
  static Future<ApiResponse> createLevel({
    required String levelName,
    required String levelTypeName,
    String? levelData,
    String? winCondition,
  }) async {
    try {
      final url = Uri.parse("$apiBase/create-level");
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'level_name': levelName,
          'level_type_name': levelTypeName,
          if (levelData != null) 'level_data': levelData,
          if (winCondition != null) 'win_condition': winCondition,
        }),
      );

      // Consider all 2xx status codes as success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Clear cache when level is created
        clearCache();

        try {
          final Map<String, dynamic> jsonData = jsonDecode(response.body);

          // Check if backend returned explicit success field
          final bool success = true;

          final String message =
              jsonData['message'] ?? "Level created successfully";

          return ApiResponse(
            success: success,
            message: message,
            data: jsonData,
          );
        } catch (e) {
          // If response is not JSON, still consider it success
          return ApiResponse(
            success: true,
            message: "Level created successfully",
          );
        }
      }

      // Non-2xx response: mark as failed and include backend body
      return ApiResponse(
        success: false,
        message:
            "Failed to create level: ${response.statusCode} ${response.body}",
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Error: $e");
    }
  }

  /// ------------------------------------------------------------
  /// UPDATE EXISTING LEVEL
  /// ------------------------------------------------------------
  static Future<ApiResponse> updateLevel({
    required String levelId,
    required String levelName,
    required String levelTypeName,
    String? levelData,
    String? winCondition,
  }) async {
    try {
      final url = Uri.parse("$apiBase/levels/$levelId");
      final headers = await _getHeaders();

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          'level_name': levelName,
          'level_type_name': levelTypeName,
          if (levelData != null) 'level_data': levelData,
          if (winCondition != null) 'win_condition': winCondition,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear cache when level is updated
        clearCache();
        return ApiResponse(
          success: true,
          message: "Level updated successfully",
        );
      }

      return ApiResponse(
        success: false,
        message: "Failed to update level: ${response.body}",
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Error: $e");
    }
  }

  /// ------------------------------------------------------------
  /// DELETE LEVEL
  /// ------------------------------------------------------------
  static Future<ApiResponse> deleteLevel(String levelId) async {
    try {
      final url = Uri.parse("$apiBase/levels/$levelId");
      final headers = await _getHeaders();

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        // Clear cache when level is deleted
        clearCache();
        return ApiResponse(
          success: true,
          message: "Level deleted successfully",
        );
      }

      return ApiResponse(
        success: false,
        message: "Failed to delete level: ${response.body}",
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Error: $e");
    }
  }

  static Future<ApiResponse> clearFiles() async {
    try {
      final url = Uri.parse("$apiBase/clear-files");
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: "files cleared successfully",
        );
      }

      return ApiResponse(
        success: false,
        message: "Failed to clear files: ${response.body}",
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Error: $e");
    }
  }

  /// ------------------------------------------------------------
  /// SAVE STUDENT PROGRESS
  /// ------------------------------------------------------------
  static Future<Map<String, dynamic>> saveStudentProgress({
    required String levelId,
    required String? savedData,
  }) async {
    try {
      final url = Uri.parse("$apiBase/level-user/$levelId/save");
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'saved_data': savedData}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to save progress: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// ------------------------------------------------------------
  /// MARK LEVEL AS COMPLETE
  /// ------------------------------------------------------------
  static Future<Map<String, dynamic>> completeLevel({
    required String levelId,
    required String userId,
  }) async {
    try {
      final url = Uri.parse("$apiBase/level-user/$levelId/$userId/complete");
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        // No body needed for this specific endpoint based on user request
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to complete level: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
