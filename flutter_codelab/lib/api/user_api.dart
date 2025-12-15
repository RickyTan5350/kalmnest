import 'dart:convert';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_codelab/api/auth_api.dart';
import 'package:flutter_codelab/constants/api_constants.dart';

class UserApi {
  // Existing base URL for single user operations
  final String _baseUrl = '${ApiConstants.baseUrl}/user';
  // New base URL for list operations
  final String _listUrl = '${ApiConstants.baseUrl}/users';

  static const validationErrorCode = 422;
  static const forbiddenErrorCode = 403;

  // --- NEW: Authentication Helper to inject Bearer Token ---
  Future<Map<String, String>> _getAuthHeaders() async {
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      // Only add Host header if NOT using a custom URL
      if (ApiConstants.customBaseUrl.isEmpty) 'Host': 'kalmnest.test',
    };

    final token = await AuthApi.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        "Authentication required. Please log in to perform this action.",
      );
    }

    headers['Authorization'] = 'Bearer $token';

    return headers;
  }
  // -----------------------------------------------------

  // --- EXISTING CREATE METHOD (Public route, no token needed) ---
  Future<void> createUser(UserData data) async {
    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          // Only add Host header if NOT using a custom URL
          if (ApiConstants.customBaseUrl.isEmpty)
            'Host': 'backend_services.test',
        },
        body: jsonEncode(data.toJson()),
      );

      if (response.statusCode == 201) {
        print('User created successfully: ${response.body}');
        return;
      } else if (response.statusCode == validationErrorCode) {
        final errorBody = jsonDecode(response.body);
        final errors = errorBody['errors'] as Map<String, dynamic>;
        String errorMessage = errors.values.expand((list) => list).join('\n');
        throw Exception('$validationErrorCode: $errorMessage');
      } else {
        throw Exception('${response.statusCode}: Failed to create user.');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // --- UPDATED GET USERS METHOD ---
  Future<List<UserListItem>> getUsers({
    String? search,
    String? roleName,
    String? accountStatus,
  }) async {
    // Build Query Parameters
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (roleName != null && roleName.isNotEmpty)
      queryParams['role_name'] = roleName;
    if (accountStatus != null && accountStatus.isNotEmpty)
      queryParams['account_status'] = accountStatus;

    // Construct URI with query params
    final uri = Uri.parse(_listUrl).replace(queryParameters: queryParams);

    try {
      // 1. Get authenticated headers
      final headers = await _getAuthHeaders();

      final response = await http.get(
        uri,
        headers: headers, // <-- USE AUTH HEADERS HERE
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // The backend returns { "message": "...", "data": [...] }
        final List<dynamic> data = jsonResponse['data'];

        return data.map((json) => UserListItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error or Auth Error: $e');
    }
  }

  // --- UPDATED GET USER DETAILS METHOD ---
  Future<UserDetails> getUserDetails(String userId) async {
    final url = Uri.parse('$_listUrl/$userId'); // results in /api/users/{id}

    try {
      final headers = await _getAuthHeaders(); // Get authenticated headers
      final response = await http.get(
        url,
        headers: headers, // <-- USE AUTH HEADERS HERE
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // The controller returns the user object directly
        return UserDetails.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load user details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error or Auth Error: $e');
    }
  }

  // --- UPDATED DELETE USER METHOD ---
  Future<void> deleteUser(String userId) async {
    final url = Uri.parse('$_listUrl/$userId');

    // 1. Get the Authorization Token
    final token = await AuthApi.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token is missing or invalid. Please re-login.',
      );
    }

    try {
      final response = await http.delete(
        url,
        // 2. Add the Authorization Header, using the dynamic $token variable
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          // Only add Host header if NOT using a custom URL
          if (ApiConstants.customBaseUrl.isEmpty)
            'Host': 'backend_services.test',
        },
      );

      if (response.statusCode == 200) {
        print('User deleted successfully: $userId');
        return;
      } else if (response.statusCode == 404) {
        throw Exception('404: User not found.');
      } else if (response.statusCode == forbiddenErrorCode) {
        // CRITICAL FIX: Throw a clean, specific message for 403 without decoding body.
        throw Exception('403: Only Administrators can delete user accounts.');
      } else {
        // Log the server's full response body on unexpected error
        print(
          'DELETE FAILED. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception(
          '${response.statusCode}: Failed to delete user. Server message: ${response.body}',
        );
      }
    } catch (e) {
      // If a FormatException (from trying to decode HTML) happens here,
      // it means the server returned an unexpected format for a non-403 error.
      if (e is FormatException) {
        throw Exception(
          'Network Error: Server returned an unexpected response format.',
        );
      }
      rethrow;
    }
  }

  // --- UPDATED UPDATE USER METHOD ---
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    // Uses the protected PUT /api/users/{id} route
    final url = Uri.parse('$_listUrl/$userId');

    // 1. Get the Authorization Token
    final token = await AuthApi.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token is missing or invalid. Please re-login.',
      );
    }

    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          // Only add Host header if NOT using a custom URL
          if (ApiConstants.customBaseUrl.isEmpty)
            'Host': 'backend_services.test',
        },
        body: jsonEncode(data), // Send the update map
      );

      if (response.statusCode == 200) {
        print('User updated successfully: ${response.body}');
        return;
      } else if (response.statusCode == validationErrorCode) {
        final errorBody = jsonDecode(response.body);
        final errors = errorBody['errors'] as Map<String, dynamic>;
        String errorMessage = errors.values.expand((list) => list).join('\n');
        throw Exception('$validationErrorCode: $errorMessage');
      } else {
        // Includes 403 Forbidden or 404 Not Found
        throw Exception(
          '${response.statusCode}: Failed to update user. Server message: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
}
