import 'dart:convert';
import 'package:flutter_codelab/student/services/local_achievement_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_codelab/constants/api_constants.dart';

final String _authApiUrl = ApiConstants.baseUrl;

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
      print('DEBUG: Sending login request to $loginUrl');

      // Use http.Request instead of http.post to control redirects
      final client = http.Client();
      final request = http.Request('POST', Uri.parse(loginUrl))
        ..followRedirects =
            false // <--- STOP AUTOMATIC REDIRECTS checking
        ..headers.addAll({
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          // Tell Laravel/Nginx we are using HTTPS to prevent redirect loops
          'X-Forwarded-Proto': 'https',
          // Only add Host header if NOT using a custom URL
          if (ApiConstants.customBaseUrl.isEmpty)
            'Host': 'backend_services.test',
        })
        ..body = body;

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response headers: ${response.headers}'); // Log ALL headers
      if (response.isRedirect) {
        print('DEBUG: Redirect Location: ${response.headers['location']}');
      }
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final userDataJson = jsonEncode(data['user']);

        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _userKey, value: userDataJson);

        final userMap = data['user'] as Map<String, dynamic>;
        userMap['token'] = token; // Add token to the map
        return userMap;
      } else if (response.statusCode == 422) {
        final errors = jsonDecode(response.body);
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
            // Only add Host header if NOT using a custom URL
            if (ApiConstants.customBaseUrl.isEmpty)
              'Host': 'backend_services.test',
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
