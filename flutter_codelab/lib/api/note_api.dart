import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/note_brief.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_codelab/models/note_data.dart';
import 'package:flutter_codelab/api/api_constants.dart';

const String _apiUrl = '${ApiConstants.baseUrl}/notes';

class NoteApi {
  static const String validationErrorCode = '422';

  // --- CREATE NOTE ---
  Future<void> createNote(NoteData data) async {
    final body = jsonEncode(data.toJson());
    try {
      print('Sending POST request to: $_apiUrl');

      final response = await http.post(
        Uri.parse('$_apiUrl/new'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 422) {
        final errors =
            jsonDecode(response.body)['errors'] as Map<String, dynamic>;
        String errorMessage = errors.values.expand((e) => e as List).join('\n');
        throw Exception('${NoteApi.validationErrorCode}:$errorMessage');
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

  // --- FETCH ALL NOTES (Brief) ---
  Future<List<NoteBrief>> fetchBriefNote() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);

        final List<NoteBrief> note = jsonResponse
            .map((item) => NoteBrief.fromJson(item as Map<String, dynamic>))
            .toList();

        return note;
      } else {
        throw Exception(
          'Failed to load achievement data. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  // --- GET CONTENT ONLY (Existing) ---
  Future<String> getNoteContent(String noteId) async {
    final url = Uri.parse('$_apiUrl/$noteId/content');

    try {
      final response = await http.get(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'] ?? '';
      } else {
        throw Exception('Failed to load note content: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching note content: $e');
    }
  }

  // --- NEW: GET FULL NOTE DETAILS (For Editing) ---
  // This fetches title, topic, visibility, AND content so the Edit Page has everything.
  Future<Map<String, dynamic>> getNote(String noteId) async {
    final url = Uri.parse('$_apiUrl/$noteId'); // Standard REST show endpoint

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Returns the full JSON object (title, topic, visibility, content, etc.)
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load note details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching note details: $e');
    }
  }

  // --- SEARCH NOTES ---
  Future<List<NoteBrief>> searchNotes(String topic, String query) async {
    try {
      final uri = Uri.parse(
        '$_apiUrl/search',
      ).replace(queryParameters: {'topic': topic, 'query': query});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        return data
            .map((item) => NoteBrief.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to search notes. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Search API Error: $e');
    }
  }

  // --- UPDATE NOTE (FIXED) ---
  // Now accepts Topic and Visibility to fix the "Too many positional arguments" error
  Future<bool> updateNote(
    String id,
    String title,
    String content,
    String topic, // <--- Added
    bool visibility, // <--- Added
  ) async {
    final url = Uri.parse('$_apiUrl/$id');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'topic': topic, // Send new topic
          'visibility': visibility
              ? 1
              : 0, // Convert bool to integer for backend
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed update: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating note: $e');
      return false;
    }
  }

  // --- DELETE NOTE ---
  Future<bool> deleteNote(String id) async {
    final url = Uri.parse('$_apiUrl/$id');

    try {
      final response = await http.delete(url);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }

  // --- DELETE MULTIPLE NOTES ---
  Future<void> deleteNotes(List<dynamic> ids) async {
    // Iterate and delete individually since no batch endpoint is known
    for (final id in ids) {
      await deleteNote(id.toString());
    }
  }
}
