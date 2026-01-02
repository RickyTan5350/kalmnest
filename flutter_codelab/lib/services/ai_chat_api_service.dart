import 'package:dio/dio.dart';
import 'package:flutter_codelab/constants/api_constants.dart';

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
    String? language,
  }) async {
    try {
      final response = await _dio.post(
        '/chat',
        data: {
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
          if (language != null) 'language': language,
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
      // Handle different error types
      if (e.response?.statusCode == 500) {
        final errorMessage =
            e.response?.data?['message'] ??
            'Server error. Please check if the AI service is configured correctly.';
        print('Server error (500): $errorMessage');
        throw Exception('AI service error: $errorMessage');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running.',
        );
      }
      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Unknown error';
      print('Dio Error: $errorMessage');
      throw Exception('Network error: $errorMessage');
    } catch (e) {
      rethrow;
    }
  }

  /// Get all chat sessions for the current user (History)
  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      final response = await _dio.get('/chat/sessions');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['status'] == 'success' && data['sessions'] is List) {
          return List<Map<String, dynamic>>.from(data['sessions']);
        }
        return [];
      } else {
        // Return empty list instead of throwing for non-critical errors
        print('Failed to load sessions: Status ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      // Handle Dio errors gracefully
      if (e.response?.statusCode == 500) {
        print(
          'Server error (500) loading sessions. Backend may not be configured yet.',
        );
        return []; // Return empty list to allow app to continue
      }
      print('Error fetching sessions: ${e.message}');
      return []; // Return empty list instead of throwing
    } catch (e) {
      print('Error fetching sessions: $e');
      return []; // Return empty list instead of throwing
    }
  }

  /// Get messages for a specific session
  Future<List<Map<String, dynamic>>> getSessionMessages(
    String sessionId,
  ) async {
    try {
      final response = await _dio.get('/chat/sessions/$sessionId/messages');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['status'] == 'success' && data['messages'] is List) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
        return [];
      } else {
        print('Failed to load messages: Status ${response.statusCode}');
        return []; // Return empty list instead of throwing
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        print('Server error (500) loading messages. Returning empty list.');
        return [];
      }
      print('Error fetching messages: ${e.message}');
      return []; // Return empty list instead of throwing
    } catch (e) {
      print('Error fetching messages: $e');
      return []; // Return empty list instead of throwing
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    try {
      final response = await _dio.delete('/chat/sessions/$sessionId');
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete session (Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('Error deleting session: $e');
      throw Exception('Failed to delete chat: $e');
    }
  }
}
