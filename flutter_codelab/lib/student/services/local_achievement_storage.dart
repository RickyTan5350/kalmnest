import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_codelab/models/achievement_data.dart';

class LocalAchievementStorage {

  // 1. GET FILE REFERENCE
  // Returns the File object pointing to: .../documents/<user_id>.json
  Future<File> _getLocalFile(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    // Explicitly naming the file as requested
    return File('${directory.path}/$userId.json');
  }

  // 2. SAVE ACHIEVEMENTS
  // Call this after successfully fetching data from the API
  Future<void> saveUnlockedAchievements(String userId, List<AchievementData> achievements) async {
    final file = await _getLocalFile(userId);

    // Convert the list of objects into a List of JSON maps
    // We use the Enriched format so the app works offline
    final String jsonString = jsonEncode(
        achievements.map((a) => {
          'achievement_id': a.achievementId,
          'title': a.achievementTitle,
          'description': a.achievementDescription,
          'icon': a.icon,
          'associated_level': a.level,
          'obtained_at': DateTime.now().toIso8601String(), // Or pass this from API if available
        }).toList()
    );

    // Write to storage
    await file.writeAsString(jsonString);
    print('Saved local achievements to: ${file.path}');
  }

  // 3. READ ACHIEVEMENTS
  // Call this when the "My Achievements" page loads
  Future<List<AchievementData>> getUnlockedAchievements(String userId) async {
    try {
      final file = await _getLocalFile(userId);

      if (!await file.exists()) {
        print('No local file found for user: $userId');
        return [];
      }

      // Read the file
      final String contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);

      // Map back to AchievementData objects
      return jsonList.map((json) => AchievementData.fromJson(json)).toList();

    } catch (e) {
      print('Error reading local achievements: $e');
      return [];
    }
  }

  // 4. CLEAR DATA (Optional)
  // Good practice to clear this on Logout
  Future<void> clearLocalCache(String userId) async {
    final file = await _getLocalFile(userId);
    if (await file.exists()) {
      await file.delete();
    }
  }
}