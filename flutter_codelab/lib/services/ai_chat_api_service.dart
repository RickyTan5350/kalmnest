import 'package:dio/dio.dart';
import 'package:flutter_codelab/constants/api_constants.dart';

/// Service to handle communication with the Laravel backend's chat endpoint.
class AiChatApiService {
  final Dio _dio;
  final String? _authToken;

  AiChatApiService({String? token}) 
    : _authToken = token,
      _dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
          if (ApiConstants.customBaseUrl.isEmpty) 'Host': 'kalmnest.test',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ));

  /// Sends a user message to the Laravel backend and retrieves the AI's response.
  Future<Map<String, dynamic>> sendMessage(String message, {String? sessionId}) async {
    try {
      final response = await _dio.post('/chat', data: {
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == 'success' && data['ai_response'] != null) {
          return {
            'ai_response': data['ai_response'].toString(),
            'session_id': data['session_id']?.toString(),
          };
        } else if (data['status'] == 'error') {
          throw Exception(data['message'] ?? 'Server error occurred.');
        }
        throw Exception('Invalid AI response format from server.');
      } else {
        throw Exception('Server error occurred (Code: ${response.statusCode}).');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      print('Dio Error: $errorMessage');
      throw Exception('Network error: $errorMessage');
    } catch (e) {
      print('General Error: $e');
      rethrow;
    }
  }

  /// Fetches all chat sessions for the current user.
  Future<List<dynamic>> getSessions() async {
    try {
      final response = await _dio.get('/chat/sessions');
      if (response.statusCode == 200) {
        return response.data['sessions'] as List<dynamic>;
      }
      throw Exception('Failed to fetch chat history.');
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches all messages for a specific session.
  Future<List<dynamic>> getSessionMessages(String sessionId) async {
    try {
      final response = await _dio.get('/chat/sessions/$sessionId/messages');
      if (response.statusCode == 200) {
        return response.data['messages'] as List<dynamic>;
      }
      throw Exception('Failed to fetch messages.');
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a specific chat session.
  Future<void> deleteSession(String sessionId) async {
    try {
      final response = await _dio.delete('/chat/sessions/$sessionId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete session.');
      }
    } catch (e) {
      rethrow;
    }
  }
}
