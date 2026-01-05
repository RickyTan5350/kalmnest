import 'dart:convert';
import 'package:code_play/student/services/local_achievement_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:code_play/constants/api_constants.dart';

// Ensure this matches your emulator/device URL
String get _authApiUrl => ApiConstants.baseUrl;

const _storage = FlutterSecureStorage();
const String _tokenKey = 'auth_token';
const String _userKey = 'user_data';

class AuthApi {
  // 1. LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    final loginUrl = '$_authApiUrl/login';
    final body = jsonEncode({
      'email': email,
      'password': password,
      'device_name': 'flutter_mobile_app',
    });

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          if (!kIsWeb && ApiConstants.customBaseUrl.isEmpty)
            'Host': 'kalmnest.test',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final token = data['token'];

          // 1. Extract the user map
          final Map<String, dynamic> userMap = Map<String, dynamic>.from(
            data['user'],
          );

          // 2. IMPORTANT: Inject the token into the user map so UserDetails model can see it
          userMap['token'] = token;

          // 3. Store the updated map and the token
          final userDataJson = jsonEncode(userMap);
          await _storage.write(key: _tokenKey, value: token);
          await _storage.write(key: _userKey, value: userDataJson);

          return userMap; // Return the map that now contains the token
        } catch (e) {
          print('JSON Decode Error: $e');
          print('Response Body: ${response.body}');
          throw Exception('Failed to decode server response. See logs.');
        }
      } else if (response.statusCode == 422) {
        final errors = jsonDecode(response.body);
        // Safely extract email error or provide default
        String errorMessage = 'Login failed.';
        if (errors['errors'] != null && errors['errors']['email'] != null) {
          errorMessage = errors['errors']['email'][0];
        }
        throw Exception(errorMessage);
      } else if (response.statusCode == 301 || response.statusCode == 302) {
        throw Exception(
          'Server Error ${response.statusCode}: Redirecting to ${response.headers['location']}',
        );
      } else {
        throw Exception(
          'Server Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('DEBUG: Login Error caught: $e');
      rethrow;
    }
  }

  // 2. TOKEN RETRIEVAL
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // 3. USER RETRIEVAL
  static Future<Map<String, dynamic>?> getStoredUser() async {
    final userDataJson = await _storage.read(key: _userKey);
    if (userDataJson != null) {
      return jsonDecode(userDataJson) as Map<String, dynamic>;
    }
    return null;
  }

  // 4. LOGOUT
  static Future<void> logout(String userId) async {
    final token = await getToken(); // Get the stored token
    final logoutUrl = '$_authApiUrl/logout'; // Target the protected endpoint

    if (token != null) {
      try {
        // Send POST request to server with the token to revoke it
        await http.post(
          Uri.parse(logoutUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token', // Crucial: Send the token
            if (!kIsWeb && ApiConstants.customBaseUrl.isEmpty)
              'Host': 'kalmnest.test',
          },
        );
      } catch (e) {
        // Handle network errors but proceed with local clear
        print('Server logout failed, proceeding with local clear: $e');
      }
    }

    // Clear secure storage on the device
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);

    // Clear the local achievement cache specific to the user
    final localStorage = LocalAchievementStorage();
    await localStorage.clearLocalCache(userId);
  }

  // 5. FORGOT PASSWORD
  Future<void> forgotPassword(String email) async {
    final url = '$_authApiUrl/forgot-password';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      // Decode error message if possible
      String msg = 'Failed to send reset code';
      try {
        msg = jsonDecode(response.body)['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // 6. RESET PASSWORD
  Future<void> resetPassword(String email, String code, String password) async {
    final url = '$_authApiUrl/reset-password';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json', // Crucial for Laravel validation errors
      },
      body: jsonEncode({
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': password,
      }),
    );

    if (response.statusCode != 200) {
      String msg = 'Failed to reset password';
      try {
        final body = jsonDecode(response.body);
        // Handle standard Laravel Error format
        if (body['message'] != null) {
          msg = body['message'];
        }
        // Handle Validation Errors key
        if (body['errors'] != null) {
          final errors = body['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            // Just grab the first error from the first field
            msg = errors.values.first[0];
          }
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
