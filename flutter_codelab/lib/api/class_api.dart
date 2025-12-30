// lib/api/class_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_codelab/api/auth_api.dart';
import 'package:flutter_codelab/constants/api_constants.dart';

class ClassApi {
  // Replace with your PC's local IP
  static String get base => ApiConstants.baseUrl;

  // Helper function to get headers with authentication
  static Future<Map<String, String>> _getAuthHeaders({
    bool requiresAuth = true,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    final token = await AuthApi.getToken();

    if (requiresAuth && token == null) {
      throw Exception(
        "Authentication required. Please log in to perform this action.",
      );
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> createClass({
    required String className,
    String? teacherId,
    String? description,
    String? adminId,
    List<String>? studentIds,
  }) async {
    final uri = Uri.parse('$base/classes');
    final body = {
      'class_name': className,
      'teacher_id': teacherId,
      'description': description ?? '',
      'admin_id': adminId,
      'student_ids': studentIds,
    };

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      print('Request body: ${jsonEncode(body)}');
      print('Response status: ${res.statusCode}');
      print('Response body: ${res.body}');

      if (res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        return {'success': true, 'data': decoded['data']};
      } else if (res.statusCode == 422) {
        final decoded = jsonDecode(res.body);
        final errors = decoded['errors'] ?? {};
        // Extract error message - prioritize class_name, then other fields
        String errorMessage = 'Validation failed.';
        if (errors['class_name'] != null && errors['class_name'].isNotEmpty) {
          errorMessage = errors['class_name'][0];
        } else if (errors['student_ids'] != null &&
            errors['student_ids'].isNotEmpty) {
          errorMessage = errors['student_ids'][0];
        } else if (errors.isNotEmpty) {
          // Get first error from any field
          final firstErrorKey = errors.keys.first;
          if (errors[firstErrorKey] != null &&
              errors[firstErrorKey].isNotEmpty) {
            errorMessage = errors[firstErrorKey][0];
          }
        } else if (decoded['message'] != null) {
          errorMessage = decoded['message'];
        }
        return {'success': false, 'message': errorMessage, 'errors': errors};
      } else {
        final decoded = jsonDecode(res.body);
        return {
          'success': false,
          'message': decoded['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('Network error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> fetchClasses(int page) async {
    final uri = Uri.parse("$base/classes?page=$page&per_page=5");

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        // Expected Laravel paginator structure
        return jsonDecode(res.body);
      } else {
        // Log and return an empty paginator structure instead of throwing
        print("Failed to load classes: ${res.statusCode} ${res.body}");
        return {
          'current_page': 1,
          'data': <dynamic>[],
          'first_page_url': null,
          'from': null,
          'last_page': 1,
          'last_page_url': null,
          'next_page_url': null,
          'path': uri.toString(),
          'per_page': 5,
          'prev_page_url': null,
          'to': null,
          'total': 0,
        };
      }
    } catch (e) {
      // On any network/parse error, also return an empty paginator
      print("Failed to load classes: $e");
      return {
        'current_page': 1,
        'data': <dynamic>[],
        'first_page_url': null,
        'from': null,
        'last_page': 1,
        'last_page_url': null,
        'next_page_url': null,
        'path': uri.toString(),
        'per_page': 5,
        'prev_page_url': null,
        'to': null,
        'total': 0,
      };
    }
  }

  // Fetch all classes without pagination
  static Future<List<dynamic>> fetchAllClasses() async {
    List<dynamic> allClasses = [];
    int currentPage = 1;
    bool hasMorePages = true;

    try {
      while (hasMorePages) {
        final data = await fetchClasses(currentPage);
        final List<dynamic> pageData = data['data'] ?? [];
        allClasses.addAll(pageData);

        final int lastPage = data['last_page'] ?? 1;
        if (currentPage >= lastPage) {
          hasMorePages = false;
        } else {
          currentPage++;
        }
      }
      return allClasses;
    } catch (e) {
      print("Error fetching all classes: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateClass(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final response = await http.put(
        Uri.parse("$base/classes/$id"),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else if (response.statusCode == 422) {
        final decoded = jsonDecode(response.body);
        final errors = decoded['errors'] ?? {};
        // Extract error message - prioritize class_name, then other fields
        String errorMessage = 'Validation failed.';
        if (errors['class_name'] != null && errors['class_name'].isNotEmpty) {
          errorMessage = errors['class_name'][0];
        } else if (errors['student_ids'] != null &&
            errors['student_ids'].isNotEmpty) {
          errorMessage = errors['student_ids'][0];
        } else if (errors.isNotEmpty) {
          // Get first error from any field
          final firstErrorKey = errors.keys.first;
          if (errors[firstErrorKey] != null &&
              errors[firstErrorKey].isNotEmpty) {
            errorMessage = errors[firstErrorKey][0];
          }
        } else if (decoded['message'] != null) {
          errorMessage = decoded['message'];
        }
        return {'success': false, 'message': errorMessage, 'errors': errors};
      } else {
        final decoded = jsonDecode(response.body);
        return {
          'success': false,
          'message': decoded['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print("Error updating class: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<bool> deleteClass(String id) async {
    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final response = await http.delete(
        Uri.parse("$base/classes/$id"),
        headers: headers,
      );

      print("DELETE STATUS: ${response.statusCode}");
      print("DELETE BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting class: $e");
      return false;
    }
  }

  // ------------------------------------------------------------------------
  // ⭐ NEW METHOD — Fetch Total Class Count (No existing code touched)
  // ------------------------------------------------------------------------
  static Future<Map<String, dynamic>> fetchClassStats() async {
    final uri = Uri.parse("$base/classes-stats");

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        print("Error fetching class stats: ${res.body}");
        return {
          'total_classes': 0,
          'total_assigned_teachers': 0,
          'total_enrolled_students': 0,
        };
      }
    } catch (e) {
      print("Network error fetching stats: $e");
      return {
        'total_classes': 0,
        'total_assigned_teachers': 0,
        'total_enrolled_students': 0,
      };
    }
  }

  static Future<Map<String, dynamic>?> fetchClassById(String classId) async {
    final uri = Uri.parse('$base/classes/$classId');

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded["data"];
      } else {
        print("Fetch class failed: ${res.body}");
        return null;
      }
    } catch (e) {
      print("Network error: $e");
      return null;
    }
  }

  // Fetch all teachers for dropdown
  static Future<List<Map<String, dynamic>>> fetchTeachers() async {
    final uri = Uri.parse('$base/users/teachers');

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.get(uri, headers: headers);

      print('Fetch teachers - Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final teachers = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
        print('Fetched ${teachers.length} teachers');
        return teachers;
      } else {
        print("Error fetching teachers: ${res.statusCode} ${res.body}");
        return [];
      }
    } catch (e, stackTrace) {
      print("Network error fetching teachers: $e");
      print("Stack trace: $stackTrace");
      return [];
    }
  }

  // Fetch all students for dropdown
  static Future<List<Map<String, dynamic>>> fetchStudents() async {
    final uri = Uri.parse('$base/users/students');

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.get(uri, headers: headers);

      print('Fetch students - Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final students = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
        print('Fetched ${students.length} students');
        return students;
      } else {
        print("Error fetching students: ${res.statusCode} ${res.body}");
        return [];
      }
    } catch (e, stackTrace) {
      print("Network error fetching students: $e");
      print("Stack trace: $stackTrace");
      return [];
    }
  }

  // ========================================================================
  // Quiz (Level) Management for Classes
  // ========================================================================

  /// Get all quizzes (levels) assigned to a class
  static Future<List<Map<String, dynamic>>> getClassQuizzes(
    String classId,
  ) async {
    final uri = Uri.parse('$base/classes/$classId/quizzes');

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(decoded['data'] ?? []);
      } else {
        print("Error fetching class quizzes: ${res.statusCode} ${res.body}");
        return [];
      }
    } catch (e) {
      print("Network error fetching class quizzes: $e");
      return [];
    }
  }

  /// Assign a quiz (level) to a class
  static Future<Map<String, dynamic>> assignQuizToClass({
    required String classId,
    required String levelId,
    bool isPrivate = false,
  }) async {
    final uri = Uri.parse('$base/classes/$classId/quizzes');
    final body = jsonEncode({'level_id': levelId, 'is_private': isPrivate});

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.post(uri, headers: headers, body: body);

      if (res.statusCode == 201) {
        return {'success': true, 'message': 'Quiz assigned successfully'};
      } else {
        final decoded = jsonDecode(res.body);
        return {
          'success': false,
          'message': decoded['message'] ?? 'Failed to assign quiz',
        };
      }
    } catch (e) {
      print("Network error assigning quiz: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Remove a quiz (level) from a class
  static Future<bool> removeQuizFromClass({
    required String classId,
    required String levelId,
  }) async {
    final uri = Uri.parse('$base/classes/$classId/quizzes/$levelId');

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.delete(uri, headers: headers);

      return res.statusCode == 200;
    } catch (e) {
      print("Network error removing quiz: $e");
      return false;
    }
  }

  /// Get quiz count for a class
  static Future<int> getClassQuizCount(String classId) async {
    final uri = Uri.parse('$base/classes/$classId/quizzes/count');

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded['total_quizzes'] ?? 0;
      } else {
        print("Error fetching quiz count: ${res.statusCode} ${res.body}");
        return 0;
      }
    } catch (e) {
      print("Network error fetching quiz count: $e");
      return 0;
    }
  }

  /// Get student completion data for a class
  /// Returns a list of students with their completion statistics
  static Future<Map<String, dynamic>> getStudentCompletion(
    String classId,
  ) async {
    final uri = Uri.parse('$base/classes/$classId/students/completion');

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return {
          'success': true,
          'data': List<Map<String, dynamic>>.from(decoded['data'] ?? []),
          'total_quizzes_assigned': decoded['total_quizzes_assigned'] ?? 0,
        };
      } else {
        print(
          "Error fetching student completion: ${res.statusCode} ${res.body}",
        );
        return {
          'success': false,
          'data': <Map<String, dynamic>>[],
          'total_quizzes_assigned': 0,
        };
      }
    } catch (e) {
      print("Network error fetching student completion: $e");
      return {
        'success': false,
        'data': <Map<String, dynamic>>[],
        'total_quizzes_assigned': 0,
      };
    }
  }

  /// Get student's quiz completion status for all quizzes in a class
  static Future<Map<String, dynamic>> getStudentQuizzes(
    String classId,
    String studentId,
  ) async {
    final uri = Uri.parse('$base/classes/$classId/students/$studentId/quizzes');

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return {
          'success': true,
          'data': List<Map<String, dynamic>>.from(decoded['data'] ?? []),
          'total_quizzes': decoded['total_quizzes'] ?? 0,
          'completed_quizzes': decoded['completed_quizzes'] ?? 0,
        };
      } else {
        print("Error fetching student quizzes: ${res.statusCode} ${res.body}");
        return {
          'success': false,
          'data': <Map<String, dynamic>>[],
          'total_quizzes': 0,
          'completed_quizzes': 0,
        };
      }
    } catch (e) {
      print("Network error fetching student quizzes: $e");
      return {
        'success': false,
        'data': <Map<String, dynamic>>[],
        'total_quizzes': 0,
        'completed_quizzes': 0,
      };
    }
  }

  /// Get quiz's student completion status for all students in a class
  static Future<Map<String, dynamic>> getQuizStudents(
    String classId,
    String levelId,
  ) async {
    final uri = Uri.parse('$base/classes/$classId/quizzes/$levelId/students');

    try {
      final headers = await _getAuthHeaders(requiresAuth: true);
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return {
          'success': true,
          'quiz': decoded['quiz'],
          'data': List<Map<String, dynamic>>.from(decoded['data'] ?? []),
          'total_students': decoded['total_students'] ?? 0,
          'completed_students': decoded['completed_students'] ?? 0,
        };
      } else {
        print("Error fetching quiz students: ${res.statusCode} ${res.body}");
        return {
          'success': false,
          'quiz': null,
          'data': <Map<String, dynamic>>[],
          'total_students': 0,
          'completed_students': 0,
        };
      }
    } catch (e) {
      print("Network error fetching quiz students: $e");
      return {
        'success': false,
        'quiz': null,
        'data': <Map<String, dynamic>>[],
        'total_students': 0,
        'completed_students': 0,
      };
    }
  }
}
