import 'package:http/http.dart' as http;
import 'dart:convert';


class FeedbackApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api'; // Laravel dev server
  
  final String? token; // Store the auth token from login

  FeedbackApiService({this.token});

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// Test if backend is reachable
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }


  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      print('Fetching students from: $baseUrl/students');
      final response = await http.get(Uri.parse('$baseUrl/students')).timeout(const Duration(seconds: 5));

      print('Students response status: ${response.statusCode}');
      print('Students response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<Map<String, dynamic>> students = List<Map<String, dynamic>>.from(
            (jsonResponse['data'] as List).map((s) {
              // Map user_id or id to 'id', name to 'name'
              final userId = s['user_id'] ?? s['id'];
              final name = s['name'] ?? 'Unknown';
              return {
                'id': userId?.toString() ?? '',
                'name': name?.toString() ?? 'Unknown',
              };
            })
          );
          print('Mapped students: $students');
          return students;
        } else {
          throw Exception('Failed to load students: ${jsonResponse['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to fetch students: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching students: $e');
    }
  }
  /// Fetch all feedback created by the teacher
  Future<List<Map<String, dynamic>>> getFeedback() async {
    try {
      final endpoint = '/feedback';
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      print('GET $baseUrl$endpoint - Status: ${response.statusCode}');
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
        throw Exception('Endpoint not found. Check API URL: $baseUrl$endpoint');
      } else {
        throw Exception('Failed to fetch feedback: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching feedback: $e');
    }
  }

  /// Create new feedback
  Future<Map<String, dynamic>> createFeedback({
    required String studentId,
    required String topic,
    required String comment,
  }) async {
    try {
      // Use public endpoint if no token provided (for testing)
      final endpoint = '/feedback';
      
      final body = jsonEncode({
        'student_id': studentId,
        'topic': topic,
        'comment': comment,
      });

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body,
      );

      print('POST $baseUrl$endpoint - Status: ${response.statusCode}');
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
        throw Exception('Endpoint not found. Check API URL: $baseUrl$endpoint');
      } else {
        throw Exception('Failed to create feedback: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating feedback: $e');
    }
  }
}
