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
    // Find the map where 'value' matches the iconValue from the API
    final entry = achievementIconOptions.firstWhere(
      (opt) => opt['value'] == iconValue,
      orElse: () => {'icon': Icons.help_outline}, // Default icon if not found
    );
    return entry['icon'] as IconData;
  } catch (e) {
    // Fallback in case of any error
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
      return Colors.grey; // Default color
  }
}
class AchievementApi {
  // Custom Exception for better error handling in the UI
  static const String validationErrorCode = '422';
  static const String studentAuthFailureMessage = 'Students are not allowed to create achievements';

  // NEW: Helper function to get headers with optional authentication
  // -------------------------------------------------------------------
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
      final headers = await _getAuthHeaders(requiresAuth: true); // Requires token

      final response = await http.post(
        Uri.parse(createAchievementApiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 422) {
        final errors = jsonDecode(response.body)['errors'] as Map<String, dynamic>;
        String errorMessage = errors.values.expand((e) => e as List).join('\n');
        throw Exception('${AchievementApi.validationErrorCode}:$errorMessage');
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        final jsonResponse = jsonDecode(response.body);
        final serverMessage = jsonResponse['message'] as String? ?? '';

        // The unauthorized message to check for (and now, to throw)
        const unauthorizedMessage = 'Access Denied: Only Admins or Teachers can create achievements.';

        if (serverMessage.contains(unauthorizedMessage)) {
          // Throw the desired specific message (wrapped in an Exception)
          throw Exception(unauthorizedMessage);
        }

        // Default message for other 401/403 errors (e.g., token expired)
        throw Exception('Access denied. You may not have the required role.');
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



  Future<List<AchievementData>> fetchBriefAchievements() async {
    try {
      final headers = await _getAuthHeaders(requiresAuth: false);
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);

        // Use the .map() to parse each JSON object into an AchievementBrief object
        final List<AchievementData> achievements = jsonResponse
            .map(
              (item) => AchievementData.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return achievements; // <-- Return the clean list of objects
      } else {
        throw Exception(
          'Failed to load achievement data. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<void> updateAchievement(String id, AchievementData data) async {
    // Construct the URL for the specific resource (PUT /api/achievements/{id})
    final updateUrl = '$_apiUrl/update/$id';

    // Convert the data object to JSON
    final body = jsonEncode(data.newAchievementToJson());

    try {
      print('Sending PUT request to: $updateUrl');
      print('Data: $body');

      final response = await http.put(
        Uri.parse(updateUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        // Success
        return;
      } else if (response.statusCode == 422) {
        // Reusing your validation error parsing logic from createAchievement
        final errors = jsonDecode(response.body)['errors'] as Map<String, dynamic>;

        // Flattens the error arrays into a single string
        String errorMessage = errors.values.expand((e) => e as List).join('\n');

        throw Exception('${AchievementApi.validationErrorCode}:$errorMessage');
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
    final body = jsonEncode({
      'ids': ids.toList(), // Convert Set to List for JSON
    });

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final response = await http.post(
        Uri.parse(deleteUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          // Add auth headers here if needed, e.g.:
          // 'Authorization': 'Bearer $yourAuthToken',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        // Success
        return;
      } else if (response.statusCode == 404) {
        throw Exception('No achievements found to delete.');
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

  Future<AchievementData> getAchievementById(String id) async {
    // Assuming your backend route is something like /api/achievements/{id}
    final url = '$_apiUrl/$id';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Convert the single JSON object to your AchievementData model
        return AchievementData.fromJson(jsonResponse);
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
      // TODO: If this fails (offline), save to a local "pending_sync" queue
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

  // Future<List<AchievementData>> fetchAndCacheAchievements(String userId) async {
  //   try {
  //     // 1. Fetch from Backend (Your existing logic)
  //     final headers = await _getAuthHeaders(requiresAuth: false);
  //     final response = await http.get(Uri.parse(_apiUrl)); //
  //
  //     if (response.statusCode == 200) {
  //       List<dynamic> jsonResponse = jsonDecode(response.body);
  //       final List<AchievementData> achievements = jsonResponse
  //           .map((item) => AchievementData.fromJson(item))
  //           .toList();
  //
  //       // 2. NEW: Save to Local File System
  //       final storage = LocalAchievementStorage();
  //       await storage.saveUnlockedAchievements(userId, achievements);
  //
  //       return achievements;
  //     } else {
  //       throw Exception('Failed to load data');
  //     }
  //   } catch (e) {
  //     // 3. FALLBACK: If API fails (offline), load from Local File
  //     print('API failed, attempting local load: $e');
  //     final storage = LocalAchievementStorage();
  //     return await storage.getUnlockedAchievements(userId);
  //   }
  // }
}
