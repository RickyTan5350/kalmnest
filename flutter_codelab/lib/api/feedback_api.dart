import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_codelab/api/auth_api.dart';
import 'package:flutter_codelab/constants/api_constants.dart';

class FeedbackApiService {
  final String? token; // Store the auth token from login

  FeedbackApiService({this.token});

  /// Build headers, preferring the passed `token`, otherwise try secure storage.
  Future<Map<String, String>> getHeaders() async {
    final Map<String, String> result = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (ApiConstants.customBaseUrl.isEmpty) 'Host': 'kalmnest.test',
    };

    String? effectiveToken = token;
    if (effectiveToken == null || effectiveToken.isEmpty) {
      try {
        effectiveToken = await AuthApi.getToken();
      } catch (e) {
        // ignore storage errors; effectiveToken will remain null
        print('FeedbackApiService: error reading stored token: $e');
      }
    }

    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      result['Authorization'] = 'Bearer $effectiveToken';
    }

    // Log whether a token was found (masked) for debugging
    try {
      final bool hasToken = effectiveToken != null && effectiveToken.isNotEmpty;
      final String masked = hasToken ? '[REDACTED]' : 'null';
      print('FeedbackApiService: token present=$hasToken token=$masked');
    } catch (_) {}

    return result;
  }

  // Helper to mask Authorization value for safe logging
  Map<String, String> _maskHeaders(Map<String, String> h) {
    final Map<String, String> copy = Map.from(h);
    if (copy.containsKey('Authorization')) {
      copy['Authorization'] = '[REDACTED]';
    }
    return copy;
  }

  /// Test if backend is reachable
  Future<bool> testConnection() async {
    try {
      final hdrs = await getHeaders();
      print(
        'FeedbackApiService GET ${ApiConstants.baseUrl}/test headers: $hdrs',
      );
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/test'), headers: hdrs)
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTopics() async {
    try {
      final endpoint = '/topics';
      final hdrs = await getHeaders();
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}$endpoint'), headers: hdrs)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> topics = data['data'] ?? [];
          return topics.map<Map<String, dynamic>>((t) => {
            'topic_id': t['topic_id']?.toString() ?? '',
            'topic_name': t['topic_name'] ?? 'Unknown',
          }).toList();
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch topics');
        }
      } else {
        throw Exception('Failed to fetch topics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching topics: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      // The backend exposes users via `/users` and supports filtering by role_name
      final endpoint = '/users?role_name=Student';
      print('Fetching students from: ${ApiConstants.baseUrl}$endpoint');
      final hdrs = await getHeaders();
      print(
        'FeedbackApiService GET ${ApiConstants.baseUrl}$endpoint headers: ${_maskHeaders(hdrs)}',
      );
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}$endpoint'), headers: hdrs)
          .timeout(const Duration(seconds: 5));

      print('Students response status: ${response.statusCode}');
      print('Students response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Controller returns { message: '...', data: [ ...users ] }
        final List<dynamic>? payloadList =
            decoded is Map && decoded['data'] is List
            ? List<dynamic>.from(decoded['data'] as List)
            : decoded is List
            ? List<dynamic>.from(decoded)
            : null;

        if (payloadList == null) {
          throw Exception('Unexpected students payload: ${response.body}');
        }

        final List<Map<String, dynamic>> students = payloadList
            .map<Map<String, dynamic>>((s) {
              final userId = (s is Map) ? (s['user_id'] ?? s['id']) : null;
              final name = (s is Map) ? (s['name'] ?? 'Unknown') : 'Unknown';
              return {
                'id': userId?.toString() ?? '',
                'name': name?.toString() ?? 'Unknown',
              };
            })
            .toList();

        print('Mapped students: $students');
        return students;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login.');
      } else {
        throw Exception(
          'Failed to fetch students: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to fetch students: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching students: $e');
    }
  }

  /// Fetch all feedback created by the teacher
  Future<List<Map<String, dynamic>>> getFeedback() async {
    try {
      final endpoint = '/feedback';

      Map<String, String> hdrs = await getHeaders();
      print(
        'FeedbackApiService GET ${ApiConstants.baseUrl}$endpoint headers: ${_maskHeaders(hdrs)}',
      );
      var response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: hdrs,
      );

      // If unauthorized, try once more after re-reading the stored token
      if (response.statusCode == 401) {
        print(
          'FeedbackApiService: received 401, refreshing token and retrying once',
        );
        print(
          'FeedbackApiService: received 401, refreshing token and retrying once',
        );
        final freshHdrs = await getHeaders();
        if (freshHdrs['Authorization'] != hdrs['Authorization']) {
          print(
            'FeedbackApiService: Authorization changed, retrying with new token',
          );
          print(
            'FeedbackApiService: Authorization changed, retrying with new token',
          );
          hdrs = freshHdrs;
          print(
            'FeedbackApiService RETRY GET ${ApiConstants.baseUrl}$endpoint headers: ${_maskHeaders(hdrs)}',
          );
          response = await http.get(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: hdrs,
          );
        } else {
          print('FeedbackApiService: Authorization unchanged after refresh');
        }
      }

      print(
        'GET ${ApiConstants.baseUrl}$endpoint - Status: ${response.statusCode}',
      );
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final feedbacks = List<Map<String, dynamic>>.from(data['data'] ?? []);
          return feedbacks;
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch feedback');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception(
          'Endpoint not found. Check API URL: ${ApiConstants.baseUrl}$endpoint',
        );
      } else {
        throw Exception(
          'Failed to fetch feedback: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to fetch feedback: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching feedback: $e');
    }
  }

  /// Fetch feedback for a specific student (requires auth)
  Future<List<Map<String, dynamic>>> getStudentFeedback(
    String studentId,
  ) async {
    try {
      final endpoint = '/feedback/student/$studentId';
      final hdrs = await getHeaders();
      print(
        'FeedbackApiService GET ${ApiConstants.baseUrl}$endpoint headers: ${_maskHeaders(hdrs)}',
      );
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: hdrs,
      );

      print(
        'GET ${ApiConstants.baseUrl}$endpoint - Status: ${response.statusCode}',
      );
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final feedbacks = List<Map<String, dynamic>>.from(data['data'] ?? []);
          return feedbacks;
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch student feedback');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception(
          'Endpoint not found. Check API URL: ${ApiConstants.baseUrl}$endpoint',
        );
      } else {
        throw Exception(
          'Failed to fetch student feedback: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching student feedback: $e');
    }
  }

  /// Create new feedback
  Future<Map<String, dynamic>> createFeedback({
    required String studentId,
    required String topicId,
    required String title,
    required String comment,
  }) async {
    try {
      final endpoint = '/feedback';

      final body = jsonEncode({
        'student_id': studentId,
        'topic_id': topicId,
        'title': title,
        'comment': comment,
      });

      final hdrs = await getHeaders();
      print(
        'FeedbackApiService POST ${ApiConstants.baseUrl}$endpoint headers: $hdrs',
      );
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: hdrs,
        body: body,
      );

      print(
        'POST ${ApiConstants.baseUrl}$endpoint - Status: ${response.statusCode}',
      );
      print('Request body: $body');
      print('Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['error'] ?? 'Failed to create feedback');
        }
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception('Validation error: ${data['errors']}');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception(
          'Endpoint not found. Check API URL: ${ApiConstants.baseUrl}$endpoint',
        );
      } else {
        throw Exception(
          'Failed to create feedback: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error creating feedback: $e');
    }
  }

  Future<void> deleteFeedback(String feedbackId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/feedback/$feedbackId');
    final hdrs = await getHeaders();
    print('FeedbackApiService DELETE $url headers: $hdrs');
    final response = await http.delete(url, headers: hdrs);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete feedback');
    }
  }

  Future<void> editFeedback({
    required String feedbackId,
    required String topicId,
    required String title,
    required String comment,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/feedback/$feedbackId');

    final hdrs = await getHeaders();
    print('FeedbackApiService PUT $url headers: $hdrs');
    final response = await http.put(
      url,
      headers: hdrs,
      body: jsonEncode({
        'topic_id': topicId,
        'title': title,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update feedback');
    }
  }
}

