import 'dart:convert';
import 'dart:io'; // Required for File AND Platform checks
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
// Ensure you import your Note model
import 'package:code_play/models/note_brief.dart';

class LocalNoteStorage {
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  // =========================================================
  // SECTION 1: API CONFIGURATION (From your previous code)
  // =========================================================

  // Dynamic URL: Checks if Android or Windows
  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    } else {
      return 'http://127.0.0.1:8000/api';
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // =========================================================
  // SECTION 2: LOCAL FILE STORAGE (Based on Achievement Storage)
  // =========================================================

  /// 1. GET FILE REFERENCE
  /// Returns a file specific to the user, e.g., "12_notes.json"
  Future<File?> _getLocalFile(String userId) async {
    if (kIsWeb) return null;
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/${userId}_notes.json');
  }

  /// 2. SAVE NOTES TO DEVICE
  /// Call this after fetching the list from the API to cache it.
  Future<void> saveLocalNotes(String userId, List<NoteBrief> notes) async {
    try {
      final file = await _getLocalFile(userId);
      if (file == null) return;

      // Convert List<NoteBrief> -> List<Map> -> JSON String
      final String jsonString = jsonEncode(
        notes.map((note) => note.toJson()).toList(),
      );

      await file.writeAsString(jsonString);
      print('Saved ${notes.length} notes locally for user $userId');
    } catch (e) {
      print('Error saving local notes: $e');
    }
  }

  /// 3. READ NOTES FROM DEVICE
  /// Call this when the app starts or is offline.
  Future<List<NoteBrief>> getLocalNotes(String userId) async {
    try {
      final file = await _getLocalFile(userId);

      if (file == null || !await file.exists()) {
        print('No local notes found for user: $userId');
        return [];
      }

      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);

      // Convert JSON List -> List<NoteBrief>
      return jsonList.map((json) => NoteBrief.fromJson(json)).toList();
    } catch (e) {
      print('Error reading local notes: $e');
      return [];
    }
  }

  /// 4. CLEAR LOCAL DATA
  Future<void> clearLocalNotes(String userId) async {
    final file = await _getLocalFile(userId);
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  // =========================================================
  // SECTION 3: API ACTIONS (Create Note)
  // =========================================================

  Future<Map<String, dynamic>> createNote({
    required String title,
    required String topic,
    required String visibility,
    required File markdownFile,
  }) async {
    final url = Uri.parse('$baseUrl/notes');
    final token = await getToken();

    if (token == null) {
      throw Exception('User is not logged in. Token not found.');
    }

    try {
      var request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['title'] = title;
      request.fields['topic'] = topic;
      request.fields['visibility'] = visibility;

      request.files.add(
        await http.MultipartFile.fromPath('file', markdownFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication Failed: Token expired or invalid.');
      } else if (response.statusCode == 422) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Validation Failed: ${errorBody['message'] ?? response.body}',
        );
      } else {
        throw Exception(
          'Failed to create note (Status ${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print("Connection Error: $e");
      rethrow;
    }
  }
}
