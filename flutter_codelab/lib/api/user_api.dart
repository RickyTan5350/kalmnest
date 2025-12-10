import 'dart:convert';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:http/http.dart' as http;

class UserApi {
  // Existing base URL for single user operations
  final String _baseUrl = 'http://backend_services.test/api/user'; 
  // New base URL for list operations
  final String _listUrl = 'http://backend_services.test/api/users';

  static const validationErrorCode = 422;
  static const forbiddenErrorCode = 403;

  // --- EXISTING CREATE METHOD ---
  Future<void> createUser(UserData data) async {
    final url = Uri.parse(_baseUrl);
    
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
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

  // --- NEW GET USERS METHOD (Filter & Search) ---
  Future<List<UserListItem>> getUsers({
    String? search,
    String? roleName,
    String? accountStatus,
  }) async {
    // Build Query Parameters
    Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (roleName != null && roleName.isNotEmpty) queryParams['role_name'] = roleName;
    if (accountStatus != null && accountStatus.isNotEmpty) queryParams['account_status'] = accountStatus;

    // Construct URI with query params
    final uri = Uri.parse(_listUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
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
      throw Exception('Network Error: $e');
    }
  }

Future<UserDetails> getUserDetails(String userId) async {
    final url = Uri.parse('$_listUrl/$userId'); // results in /api/users/{id}

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // The controller returns the user object directly
        return UserDetails.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load user details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
  
}