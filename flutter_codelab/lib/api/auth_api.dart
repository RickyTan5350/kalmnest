import 'dart:convert';
import 'package:flutter_codelab/student/services/local_achievement_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Ensure this matches your emulator/device URL
const String _authApiUrl = 'http://backend_services.test/api';

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
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        // The 'user' object from backend now includes the nested 'role' object
        // We store this entire structure securely.
        final userDataJson = jsonEncode(data['user']);

        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _userKey, value: userDataJson);

        return data['user'] as Map<String, dynamic>;
      } else if (response.statusCode == 422) {
        final errors = jsonDecode(response.body);
        // Safely extract email error or provide default
        String errorMessage = 'Login failed.';
        if (errors['errors'] != null && errors['errors']['email'] != null) {
          errorMessage = errors['errors']['email'][0];
        }
        throw Exception(errorMessage);
      } else {
        throw Exception('Server Error ${response.statusCode}');
      }
    } catch (e) {
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
}