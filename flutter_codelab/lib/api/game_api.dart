import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:code_play/models/level.dart';
import 'package:code_play/api/auth_api.dart';
import 'package:code_play/constants/api_constants.dart';

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
      if (!forceRefresh && cacheKey != null && _cachedLevelsByUser[cacheKey] != null && topic == null) {
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
      return [];
    } catch (e) {
      print("Error fetching levels: $e");
      return [];
    }
  }

  /// ------------------------------------------------------------
  /// FETCH A SINGLE LEVEL BY ID → RETURNS LevelModel?
  /// ------------------------------------------------------------
  static Future<LevelModel?> fetchLevelById(String levelId) async {
    try {
      final url = Uri.parse("$apiBase/level/$levelId");
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return LevelModel.fromJson(jsonData);
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
}

