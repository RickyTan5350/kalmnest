import 'package:dio/dio.dart';
import 'package:code_play/constants/api_constants.dart';

/// Service to handle communication with the Laravel backend's chat endpoint.
class AiChatApiService {
  final Dio _dio;

  AiChatApiService({String? token})
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          contentType: 'application/json',
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

  /// Sends a user message to the Laravel backend and retrieves the AI's response.
  Future<Map<String, dynamic>> sendMessage(
    String message, {
    String? sessionId,
  }) async {
    try {
      final response = await _dio.post(
        '/chat',
        data: {
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['status'] == 'success' && data['ai_response'] != null) {
          return {
            'ai_response': data['ai_response'].toString(),
            'session_id': data['session_id']?.toString(),
          };
        }
        throw Exception('Invalid AI response format from server.');
      } else {
        throw Exception(
          'Server error occurred (Code: ${response.statusCode}).',
        );
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      print('Dio Error: $errorMessage');
      throw Exception('Network error: $errorMessage');
    } catch (e) {
      rethrow;
    }
  }
}
