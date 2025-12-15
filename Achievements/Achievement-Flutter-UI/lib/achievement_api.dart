import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // Remember to add http dependency
import 'package:uuid/uuid.dart'; // Remember to add uuid dependency

// --- 1. Achievement Model (API Focused) ---

class AchievementApi {
  // Fields match the Laravel model structure (snake_case in JSON, camelCase in Dart)
  // This model is specifically designed for the API response which includes timestamps.
  final String achievementId;
  final String achievementName;
  final String title;
  final String? description;
  final String type;
  final String levelId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  AchievementApi({
    required this.achievementId,
    required this.achievementName,
    required this.title,
    this.description,
    required this.type,
    required this.levelId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create Achievement from a Laravel API JSON Map
  factory AchievementApi.fromJson(Map<String, dynamic> json) {
    return AchievementApi(
      achievementId: json['achievement_id'] as String,
      achievementName: json['achievement_name'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      levelId: json['level_id'] as String,
      createdBy: json['created_by'] as String,
      // The API returns strings for timestamps
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert the Dart object into a Map (for sending to the Laravel API)
  Map<String, dynamic> toJson() {
    // Only send the fillable fields required by the API
    return {
      'achievement_name': achievementName,
      'title': title,
      'description': description,
      'type': type,
      'level_id': levelId,
      'created_by': createdBy,
    };
  }
}

// --- 2. API Service Helper ---

class AchievementApiService {
  // Base URL pointing to your Laravel API (adjust for your environment)
  // Use http://10.0.2.2:8000 for Android emulator accessing localhost
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1/achievements';

  // Headers needed for JSON communication
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // 'Authorization': 'Bearer YOUR_SANCTUM_TOKEN', // Add Auth if required
  };

  /*
   * Fetches all Achievements from the Laravel API. (GET /api/v1/achievements)
   */
  Future<List<AchievementApi>> fetchAchievements() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl), headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Assuming the Laravel controller wraps data in a 'data' key (as per implementation)
        final List<dynamic> achievementJson = jsonResponse['data'] ?? [];

        return achievementJson
            .map((json) => AchievementApi.fromJson(json))
            .toList();
      } else {
        if (kDebugMode) {
          print('Failed to load achievements. Status: ${response.statusCode}');
        }
        // Handle API error response
        throw Exception('Failed to load achievements: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Network/Parsing Error: $e');
      }
      throw Exception('Failed to connect to API or parse data.');
    }
  }

  /*
   * Creates a new Achievement via the Laravel API. (POST /api/v1/achievements)
   */
  Future<AchievementApi> createAchievement(AchievementApi achievement) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode(
          achievement.toJson(),
        ), // Convert Dart object to JSON body
      );

      if (response.statusCode == 201) {
        // 201 Created status
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // Assuming the Laravel controller returns the created data in a 'data' key
        return AchievementApi.fromJson(jsonResponse['data']);
      } else {
        if (kDebugMode) {
          print('Failed to create achievement. Status: ${response.statusCode}');
        }
        throw Exception('Failed to create achievement: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Network/Parsing Error during creation: $e');
      }
      throw Exception('Failed to connect to API or parse response.');
    }
  }
}
