class AchievementData {
  final String achievementName;
  final String achievementTitle;
  final String achievementDescription;
  final String? level;

  AchievementData({
    required this.achievementName,
    required this.achievementTitle,
    required this.achievementDescription,
    this.level,
  });

  Map<String, dynamic> toJson() {
    return {
      'achievement_name': achievementName,
      'title': achievementTitle,
      'description': achievementDescription,
      'associated_level': level,
    };
  }
}
