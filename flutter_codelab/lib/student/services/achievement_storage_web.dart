import 'dart:convert';
import 'package:code_play/models/achievement_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'achievement_storage_interface.dart';

class LocalAchievementStorage implements AchievementStorage {
  static const String _boxName = 'achievements_box';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  @override
  Future<void> saveUnlockedAchievements(
    String userId,
    List<AchievementData> achievements,
  ) async {
    final box = await _getBox();

    // Convert the list of objects into a List of JSON maps
    final List<Map<String, dynamic>> achievementMaps = achievements
        .map((a) => a.toJson())
        .toList();

    // Store as JSON string for key simplicity and consistency
    final String jsonString = jsonEncode(achievementMaps);

    // Use userId as the key in the Hive box
    await box.put(userId, jsonString);
    print('Saved local achievements to Hive for user: $userId');
  }

  @override
  Future<List<AchievementData>> getUnlockedAchievements(String userId) async {
    final box = await _getBox();

    final String? jsonString = box.get(userId);

    if (jsonString == null) {
      print('No local achievements found in Hive for user: $userId');
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => AchievementData.fromJson(json)).toList();
    } catch (e) {
      print('Error decoding local achievements from Hive: $e');
      return [];
    }
  }

  @override
  Future<void> clearLocalCache(String userId) async {
    final box = await _getBox();
    await box.delete(userId);
    print('Cleared local achievements from Hive for user: $userId');
  }
}
