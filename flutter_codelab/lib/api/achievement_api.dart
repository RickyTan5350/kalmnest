import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_codelab/models/achievement_data.dart';

const String _apiUrl = 'http://127.0.0.1:8000/api/achievements';

class AchievementApi {
  // Custom Exception for better error handling in the UI
  static const String validationErrorCode = '422';

  Future<void> createAchievement(AchievementData data) async {
    //toJson() is a self-defined function in achievement_data.dart
    //jsonEncode(): convert dart object to JSON format
    final body = jsonEncode(data.toJson());
    try{
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        }, 
        body: body,
      );

      //http code 200: ok
      //http code 201: created
      if(response.statusCode == 201 || response.statusCode == 200){
        return;
      
      } else if(response.statusCode == 422){
        //decodes error JSON file, and parses into MAP
        final errors = jsonDecode(response.body)['errors'] as Map<String, dynamic>;

        //errors.values: gets list of errors, returns Iterable
        //.expand(()): basically a for loop to process array
        String errorMessage = errors.values.expand((e) => e as List).join('\n');

        throw Exception('${AchievementApi.validationErrorCode}:$errorMessage');
      
      } else {
        throw Exception('Server Error ${response.statusCode}: ${response.body}');
      }     
      
    }catch(e){
      print('Network/API Exception: $e');
      rethrow;
    }
  }
}
