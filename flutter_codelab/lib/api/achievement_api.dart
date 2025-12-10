import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_codelab/student/services/local_achievement_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';
import 'auth_api.dart';

//server URL: set your own
const String _apiUrl = 'http://backend_services.test/api/achievements';

IconData _getIconData(String iconValue) {
  try {
    final entry = achievementIconOptions.firstWhere(
          (opt) => opt['value'] == iconValue,
      orElse: () => {'icon': Icons.help_outline},
    );
    return entry['icon'] as IconData;
  } catch (e) {
    return Icons.help_outline;
  }
}

Color _getColor(String iconValue) {
  switch (iconValue) {
    case 'html':
      return Colors.orange;
    case 'css':
      return Colors.green;
    case 'javascript':
      return Colors.yellow;
    case 'php':
      return Colors.blue;
    case 'backend':
      return Colors.deepPurple;
    default:
      return Colors.grey;
  }
}

class AchievementApi {
  static const String validationErrorCode = '422';
  static const String studentAuthFailureMessage = 'Students are not allowed to create achievements';

  Future<Map<String, String>> _getAuthHeaders({bool requiresAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    final token = await AuthApi.getToken();

    if (requiresAuth && token == null) {
      throw Exception("Authentication required. Please log in to perform this action.");
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<void> createAchievement(AchievementData data) async {
    final createAchievementApiUrl = '$_apiUrl/new';
    final body = jsonEncode(data.newAchievementToJson());

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);

      final response = await http.post(
        Uri.parse(createAchievementApiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 422) {
        // --- CHANGED: Preserve structure by encoding to JSON ---
        final errors = jsonDecode(response.body)['errors'];
        // pass the raw JSON string of errors so the UI can parse it
        throw Exception('${AchievementApi.validationErrorCode}:${jsonEncode(errors)}');
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        final jsonResponse = jsonDecode(response.body);
        final serverMessage = jsonResponse['message'] as String? ?? '';
        const unauthorizedMessage = 'Access Denied: Only Admins or Teachers can create achievements.';

        if (serverMessage.contains(unauthorizedMessage)) {
          throw Exception(unauthorizedMessage);
        }
        throw Exception('Access denied. You may not have the required role.');
      } else {
        // Pass the body so we can parse SQL errors if needed
        throw Exception(
          'Server Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('Network/API Exception: $e');
      rethrow;
    }
  }

  Future<List<AchievementData>> fetchBriefAchievements() async {
    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final response = await http.get(Uri.parse(_apiUrl), headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        final List<AchievementData> achievements = jsonResponse
            .map((item) => AchievementData.fromJson(item as Map<String, dynamic>))
            .toList();
        return achievements;
      } else if(response.statusCode == 403){
        throw Exception('Access Denied: You do not have permission to view achievements.');
      } else {
        throw Exception('Failed to load achievement data. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<void> updateAchievement(String id, AchievementData data) async {
    final updateUrl = '$_apiUrl/update/$id';
    final body = jsonEncode(data.newAchievementToJson());

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);

      final response = await http.put(
        Uri.parse(updateUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 422) {
        // --- CHANGED: Preserve structure by encoding to JSON ---
        final errors = jsonDecode(response.body)['errors'];
        throw Exception('${AchievementApi.validationErrorCode}:${jsonEncode(errors)}');
      } else if (response.statusCode == 404) {
        throw Exception('Achievement not found (404).');
      } else {
        throw Exception(
          'Server Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('Network/API Exception: $e');
      rethrow;
    }
  }

  Future<void> deleteAchievements(Set<String> ids) async {
    final deleteUrl = '$_apiUrl/delete-batch';
    final body = jsonEncode({'ids': ids.toList()});

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final response = await http.post(
        Uri.parse(deleteUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('No achievements found to delete.');
      } else {
        throw Exception('Server Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Network/API Exception: $e');
      rethrow;
    }
  }

  Future<AchievementData> getAchievementById(String id) async {
    final url = '$_apiUrl/$id';

    try {
      // 1. Add Authentication Headers (Bearer Token)
      final headers = await _getAuthHeaders(requiresAuth: true);

      // 2. Send request WITH headers
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return AchievementData.fromJson(jsonResponse);
      } else if (response.statusCode == 403) {
        // 3. Handle Access Denied (e.g., if a Student tries to view Admin details)
        throw Exception('Access Denied: You do not have permission to view this achievement.');
      } else if (response.statusCode == 404) {
        throw Exception('Achievement not found.');
      } else {
        throw Exception('Failed to load details. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching details: $e');
      rethrow;
    }
  }

  Future<void> unlockAchievement(String achievementId) async {
    final url = '$_apiUrl/unlock';
    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final body = jsonEncode({'achievement_id': achievementId});
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode != 200) {
        throw Exception('Failed to sync unlock to cloud');
      }
    } catch (e) {
      print("Offline? Could not sync unlock: $e");
    }
  }

  Future<List<AchievementData>> fetchMyUnlockedAchievements() async {
    final url = '$_apiUrl/my-achievements';
    final headers = await _getAuthHeaders(requiresAuth: true);
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((item) => AchievementData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch user progress');
    }
  }
}