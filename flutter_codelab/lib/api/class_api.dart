// lib/api/class_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/class_data.dart';

class ClassApi {
  // Replace with your PC's local IP
  static const String base = 'http://127.0.0.1:8000/api';

  static Future<Map<String, dynamic>> createClass({
    required String className,
    required int teacherId,
    String? description,
    required int adminId,
  }) async {
    final uri = Uri.parse('$base/classes');
    final body = {
      'class_name': className,
      'teacher_id': teacherId,
      'description': description ?? '',
      'admin_id': adminId,
    };

    try {
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
        return {'success': false, 'errors': decoded['errors']};
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
    final uri = Uri.parse(
      "$base/classes?page=$page&per_page=5",
    );

    final res = await http.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load classes");
    }
  }

  static Future<bool> updateClass(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$base/classes/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteClass(String id) async {
    final response = await http.delete(
      Uri.parse("$base/classes/$id"),
    );

    print("DELETE STATUS: ${response.statusCode}");
    print("DELETE BODY: ${response.body}");

    return response.statusCode == 200;
  }
}
