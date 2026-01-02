import 'package:dio/dio.dart';
import 'package:flutter__codelab/constants/api_constants.dart';

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
        } else if (data['status'] == 'error') {
          throw Exception(data['message'] ?? 'Server error occurred.');
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
<<<<<<< HEAD
  /// Get all chat sessions for the current user (History)
  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      final response = await _dio.get('/chat/sessions');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['sessions']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching sessions: $e');
      throw Exception('Failed to load chat history');
    }
  }

  /// Get messages for a specific session
  Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId) async {
=======

  Future<List<Map<String, dynamic>>> getSessionMessages(
    String sessionId,
  ) async {
>>>>>>> 9781fd312f86e3acdd7af249727fa864683b259a
    try {
      final response = await _dio.get('/chat/sessions/$sessionId/messages');

      if (response.statusCode == 200) {
<<<<<<< HEAD
         final data = response.data;
         if (data['status'] == 'success') {
           return List<Map<String, dynamic>>.from(data['messages']);
         }
      }
      return [];
    } catch (e) {
      print('Error fetching messages: $e');
      throw Exception('Failed to load messages');
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _dio.delete('/chat/sessions/$sessionId');
    } catch (e) {
      print('Error deleting session: $e');
      throw Exception('Failed to delete chat');
=======
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['status'] == 'success' && data['messages'] is List) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
        return [];
      } else {
        throw Exception(
          'Failed to load messages (Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      final response = await _dio.delete('/chat/sessions/$sessionId');
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete session (Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  Future<List<dynamic>> getSessions() async {
    try {
      final response = await _dio.get('/chat/sessions');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data;
        } else if (data['sessions'] is List) {
          return data['sessions'];
        }
        return [];
      } else {
        throw Exception('Failed to load sessions');
      }
    } catch (e) {
      throw Exception('Failed to load sessions: $e');
>>>>>>> 9781fd312f86e3acdd7af249727fa864683b259a
    }
  }
}
