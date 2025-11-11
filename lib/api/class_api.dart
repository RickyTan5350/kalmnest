// lib/api/class_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ClassApi {
  // Replace with your PC's local IP
  static const String base = 'http://10.216.98.9:8000/api';

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
}
