import 'package:code_play/models/achievement_data.dart';

abstract class AchievementStorage {
  Future<void> saveUnlockedAchievements(
    String userId,
    List<AchievementData> achievements,
  );
  Future<List<AchievementData>> getUnlockedAchievements(String userId);
  Future<void> clearLocalCache(String userId);
}
